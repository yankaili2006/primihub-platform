package com.primihub.biz.service.data;


import com.primihub.biz.config.base.BaseConfiguration;
import com.primihub.biz.config.base.OrganConfiguration;
import com.primihub.biz.convert.DataTaskConvert;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.data.base.DataPirKeyQuery;
import com.primihub.biz.entity.data.dataenum.TaskStateEnum;
import com.primihub.biz.entity.data.dataenum.TaskTypeEnum;
import com.primihub.biz.entity.data.po.DataPirTask;
import com.primihub.biz.entity.data.po.DataResource;
import com.primihub.biz.entity.data.po.DataTask;
import com.primihub.biz.entity.data.req.DataPirReq;
import com.primihub.biz.entity.data.req.DataPirTaskReq;
import com.primihub.biz.entity.data.vo.DataPirTaskDetailVo;
import com.primihub.biz.entity.data.vo.DataPirTaskVo;
import com.primihub.biz.repository.primarydb.data.DataTaskPrRepository;
import com.primihub.biz.repository.secondarydb.data.DataResourceRepository;
import com.primihub.biz.repository.secondarydb.data.DataTaskRepository;
import com.primihub.biz.util.FileUtil;
import com.primihub.biz.util.snowflake.SnowflakeId;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Slf4j
public class PirService {
    @Autowired
    private BaseConfiguration baseConfiguration;
    @Autowired
    private OrganConfiguration organConfiguration;
    @Autowired
    private OtherBusinessesService otherBusinessesService;
    @Autowired
    private DataTaskPrRepository dataTaskPrRepository;
    @Autowired
    private DataTaskRepository dataTaskRepository;
    @Autowired
    private DataResourceRepository dataResourceRepository;
    @Autowired
    private DataAsyncService dataAsyncService;

    public String getResultFilePath(String taskId,String taskDate){
        return new StringBuilder().append(baseConfiguration.getResultUrlDirPrefix()).append(taskDate).append("/").append(taskId).append(".csv").toString();
    }
    public BaseResultEntity pirSubmitTask(DataPirReq req, String pirParam) {
        // Try local database lookup first (works without Fusion service)
        BaseResultEntity dataResource = otherBusinessesService.getDataResource(req.getResourceId());
        Map<String, Object> pirDataResource = null;
        DataResource localResource = null;
        String resourceColumnNames = null;
        String organName = null;
        String resourceName = null;
        boolean useFusion = dataResource.getCode() == 0
                && dataResource.getResult() != null
                && !(dataResource.getResult() instanceof LinkedHashMap
                     && ((LinkedHashMap)dataResource.getResult()).isEmpty());
        if (useFusion) {
            pirDataResource = (LinkedHashMap)dataResource.getResult();
            String availableStr = pirDataResource.getOrDefault("available","0").toString();
            int available = Integer.parseInt(availableStr);
            if (available == 1) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL,"资源不可用");
            }
            resourceColumnNames = pirDataResource.getOrDefault("resourceColumnNameList", "").toString();
            organName = pirDataResource.get("organName").toString();
            resourceName = pirDataResource.get("resourceName").toString();
        } else {
            // Fallback: lookup resource from local database
            try {
                localResource = dataResourceRepository.queryDataResourceById(Long.parseLong(req.getResourceId()));
            } catch (NumberFormatException e) {
                localResource = dataResourceRepository.queryDataResourceByResourceFusionId(req.getResourceId());
            }
            if (localResource == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL,"资源查询失败");
            }
            resourceColumnNames = localResource.getFileHandleField();
            organName = organConfiguration.getSysLocalOrganName();
            if (StringUtils.isBlank(organName)) {
                organName = "本地机构";
            }
            resourceName = localResource.getResourceName();
        }
        if (StringUtils.isBlank(resourceColumnNames)){
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL,"获取资源字段列表失败");
        }
        String[] resourceColumnNameArray = resourceColumnNames.split(",");
        if (resourceColumnNameArray.length == 0) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL,"获取资源字段列表为空");
        }

        String[] queryColumnNames = {
                resourceColumnNameArray[0]
        };
        // convert pirParam to query array
        List<DataPirKeyQuery> dataPirKeyQueries = convertPirParamToQueryArray(pirParam,queryColumnNames);

        DataTask dataTask = new DataTask();
        dataTask.setTaskIdName(Long.toString(SnowflakeId.getInstance().nextId()));
        dataTask.setTaskName(req.getTaskName());
        dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataTask.setTaskType(TaskTypeEnum.PIR.getTaskType());
        dataTask.setTaskStartTime(System.currentTimeMillis());
        dataTaskPrRepository.saveDataTask(dataTask);
        DataPirTask dataPirTask = new DataPirTask();
        dataPirTask.setTaskId(dataTask.getTaskId());
        dataPirTask.setRetrievalId(pirParam);
        dataPirTask.setProviderOrganName(organName);
        dataPirTask.setResourceName(resourceName);
        // Use fusion resource ID (not local DB ID) so the engine can resolve the dataset via meta service
        String engineResourceId = useFusion && pirDataResource != null
            ? req.getResourceId()
            : (localResource != null ? localResource.getResourceFusionId() : req.getResourceId());
        dataPirTask.setResourceId(engineResourceId);
        dataTaskPrRepository.saveDataPirTask(dataPirTask);
        dataAsyncService.pirGrpcTask(dataTask,dataPirTask,resourceColumnNames,dataPirKeyQueries);
        Map<String, Object> map = new HashMap<>();
        map.put("taskId",dataTask.getTaskId());
        return BaseResultEntity.success(map);
    }

    private static List<DataPirKeyQuery> convertPirParamToQueryArray(String pirParam, String[] resourceColumnNameArray) {
        DataPirKeyQuery dataPirKeyQuery = new DataPirKeyQuery();
        // 默认只有第一列
        dataPirKeyQuery.setKey(resourceColumnNameArray);
        String[] split = pirParam.split(",");
        List<String[]> singleValueQuery = Arrays.stream(split).map(String::trim).filter(StringUtils::isNotBlank)
                .map(s -> new String[]{s}).collect(Collectors.toList());
        dataPirKeyQuery.setQuery(singleValueQuery);
        return Collections.singletonList(dataPirKeyQuery);
    }

    public BaseResultEntity getPirTaskList(DataPirTaskReq req) {
        List<DataPirTaskVo> dataPirTaskVos = dataTaskRepository.selectDataPirTaskPage(req);
        if (dataPirTaskVos.isEmpty()) {
            return BaseResultEntity.success(new PageDataEntity(0,req.getPageSize(),req.getPageNo(),new ArrayList()));
        }
        Integer tolal = dataTaskRepository.selectDataPirTaskCount(req);
        Map<String,LinkedHashMap<String, Object>> resourceMap= new HashMap<>();
        List<String> ids = dataPirTaskVos.stream().map(DataPirTaskVo::getResourceId).collect(Collectors.toList());
        BaseResultEntity baseResult = otherBusinessesService.getResourceListById(ids);
        if (baseResult.getCode()==0){
            List<LinkedHashMap<String,Object>> voList = (List<LinkedHashMap<String,Object>>)baseResult.getResult();
            if (voList != null && voList.size()!=0){
                resourceMap.putAll(voList.stream().collect(Collectors.toMap(data -> data.get("resourceId").toString(), Function.identity())));
            }
        }
        for (DataPirTaskVo dataPirTaskVo : dataPirTaskVos) {
            if (resourceMap.containsKey(dataPirTaskVo.getResourceId())){
                DataTaskConvert.dataPirTaskPoConvertDataPirTaskVo(dataPirTaskVo,resourceMap.get(dataPirTaskVo.getResourceId()));
            }
        }
        return BaseResultEntity.success(new PageDataEntity(tolal,req.getPageSize(),req.getPageNo(),dataPirTaskVos));
    }

    public BaseResultEntity getPirTaskDetail(Long taskId) {
        DataPirTask task = dataTaskRepository.selectPirTaskById(taskId);
        if (task==null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL,"未查询到任务信息");
        }
        DataTask dataTask = dataTaskRepository.selectDataTaskByTaskId(taskId);
        if (dataTask==null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL,"未查询到任务详情");
        }
        DataPirTaskDetailVo vo = new DataPirTaskDetailVo();
        List<LinkedHashMap<String, Object>> list = null;
        if (StringUtils.isNotEmpty(dataTask.getTaskResultPath())){
            vo.setList(FileUtil.getCsvData(dataTask.getTaskResultPath(), 50));
        }
        vo.setTaskName(dataTask.getTaskName());
        vo.setTaskIdName(dataTask.getTaskIdName());
        vo.setTaskState(dataTask.getTaskState());
        vo.setOrganName(task.getProviderOrganName());
        vo.setResourceName(task.getResourceName());
        vo.setResourceId(task.getResourceId());
        vo.setRetrievalId(task.getRetrievalId());
        vo.setTaskError(dataTask.getTaskErrorMsg());
        vo.setCreateDate(dataTask.getCreateDate());
        vo.setTaskStartTime(dataTask.getTaskStartTime());
        vo.setTaskEndTime(dataTask.getTaskEndTime());
        return BaseResultEntity.success(vo);
    }


}
