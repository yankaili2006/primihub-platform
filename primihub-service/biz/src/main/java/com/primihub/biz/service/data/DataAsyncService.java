package com.primihub.biz.service.data;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.primihub.biz.config.base.BaseConfiguration;
import com.primihub.biz.config.base.OrganConfiguration;
import com.primihub.biz.config.mq.SingleTaskChannel;
import com.primihub.biz.constant.DataConstant;
import com.primihub.biz.entity.base.BaseFunctionHandleEntity;
import com.primihub.biz.entity.base.BaseFunctionHandleEnum;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.vo.DataResourceCopyVo;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.base.DataPirKeyQuery;
import com.primihub.biz.entity.data.dataenum.ModelStateEnum;
import com.primihub.biz.entity.data.dataenum.TaskStateEnum;
import com.primihub.biz.entity.data.dataenum.TaskTypeEnum;
import com.primihub.biz.entity.data.dto.ModelOutputPathDto;
import com.primihub.biz.entity.data.po.*;
import com.primihub.biz.entity.data.req.*;
import com.primihub.biz.entity.data.vo.ModelProjectResourceVo;
import com.primihub.biz.entity.data.vo.ShareModelVo;
import com.primihub.biz.entity.sys.po.SysUser;
import com.primihub.biz.repository.primarydb.data.*;
import com.primihub.biz.repository.primaryredis.data.DataRedisRepository;
import com.primihub.biz.repository.secondarydb.data.DataModelRepository;
import com.primihub.biz.repository.secondarydb.data.DataProjectRepository;
import com.primihub.biz.repository.secondarydb.data.DataResourceRepository;
import com.primihub.biz.repository.secondarydb.data.DataTaskRepository;
import com.primihub.biz.repository.secondarydb.sys.SysUserSecondarydbRepository;
import com.primihub.biz.service.data.component.ComponentTaskService;
import com.primihub.biz.service.sys.LogManagementService;
import com.primihub.biz.service.sys.SysEmailService;
import com.primihub.biz.util.CsvUtil;
import com.primihub.biz.util.DataUtil;
import com.primihub.biz.util.FileUtil;
import com.primihub.biz.util.crypt.DateUtil;
import com.primihub.biz.util.snowflake.SnowflakeId;
import com.primihub.sdk.task.TaskHelper;
import com.primihub.sdk.task.dataenum.ModelTypeEnum;
import com.primihub.sdk.task.param.TaskComponentParam;
import com.primihub.sdk.task.param.TaskPIRParam;
import com.primihub.sdk.task.param.TaskPSIParam;
import com.primihub.sdk.task.param.TaskParam;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Service;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.FutureTask;
import java.util.function.Function;
import java.util.stream.Collectors;

import static com.primihub.biz.constant.DataConstant.PYTHON_GUEST_DATASET;
import static com.primihub.biz.constant.DataConstant.PYTHON_LABEL_DATASET;

/**
 * psi 异步调用实现
 */
@Service
@Slf4j
public class DataAsyncService implements ApplicationContextAware {

    private static ApplicationContext context;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        context = applicationContext;
    }
    @Autowired
    private BaseConfiguration baseConfiguration;
    @Autowired
    private OrganConfiguration organConfiguration;
    @Autowired
    private DataResourceRepository dataResourceRepository;
    @Autowired
    private DataModelRepository dataModelRepository;
    @Autowired
    private DataPsiPrRepository dataPsiPrRepository;
    @Autowired
    private OtherBusinessesService otherBusinessesService;
    @Autowired
    private DataTaskPrRepository dataTaskPrRepository;
    @Autowired
    private DataTaskRepository dataTaskRepository;
    @Autowired
    private DataProjectRepository dataProjectRepository;
    @Autowired
    private DataProjectPrRepository dataProjectPrRepository;
    @Autowired
    private DataModelPrRepository dataModelPrRepository;
    @Autowired
    private DataReasoningPrRepository dataReasoningPrRepository;
    @Autowired
    private SingleTaskChannel singleTaskChannel;
    @Autowired
    private SysUserSecondarydbRepository sysUserSecondarydbRepository;
    @Autowired
    private SysEmailService sysEmailService;
    @Autowired
    private ThreadPoolTaskExecutor primaryThreadPool;
    @Autowired
    private DataRedisRepository dataRedisRepository;
    @Autowired
    private TaskHelper taskHelper;
    @Autowired
    private DataDifferencePrRepository dataDifferencePrRepository;
    @Autowired
    private DataUnionPrRepository dataUnionPrRepository;
    @Autowired
    private LogManagementService logManagementService;

    public TaskHelper getTaskHelper(){
        return taskHelper;
    }


    public BaseResultEntity executeBeanMethod(boolean isCheck, DataComponentReq req, ComponentTaskReq taskReq) {
        String baenName = req.getComponentCode() + DataConstant.COMPONENT_BEAN_NAME_SUFFIX;
        log.info("execute : {}", baenName);
        try {
            ComponentTaskService taskService = (ComponentTaskService) context.getBean(baenName);
            if (taskService == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL, req.getComponentName() + "组件无实现方法");
            }
            return isCheck ? taskService.check(req, taskReq) : taskService.runTask(req, taskReq);
        } catch (Exception e) {
            log.info("ComponentCode:{} -- e:{}", req.getComponentCode(), e.getMessage());
            return BaseResultEntity.failure(BaseResultEnum.DATA_RUN_TASK_FAIL, req.getComponentName() + "组件执行异常");
        }
    }


    @Async
    public void runModelTask(ComponentTaskReq req) {
        log.info("start model task grpc modelId:{} modelName:{} end time:{}", req.getDataModel().getModelId(), req.getDataModel().getModelName(), System.currentTimeMillis());
        for (DataComponent dataComponent : req.getDataComponents()) {
            dataComponent.setModelId(req.getDataModelTask().getModelId());
            dataComponent.setTaskId(req.getDataModelTask().getTaskId());
            dataModelPrRepository.saveDataComponent(dataComponent);
        }
        try {
            Map<String, DataComponent> dataComponentMap = req.getDataComponents().stream().collect(Collectors.toMap(DataComponent::getComponentCode, Function.identity()));
            for (DataModelComponent dataModelComponent : req.getDataModelComponents()) {
                dataModelComponent.setModelId(req.getDataModelTask().getModelId());
                dataModelComponent.setTaskId(req.getDataModelTask().getTaskId());
                dataModelComponent.setInputComponentId(dataModelComponent.getInputComponentCode() == null ? null : dataComponentMap.get(dataModelComponent.getInputComponentCode()) == null ? null : dataComponentMap.get(dataModelComponent.getInputComponentCode()).getComponentId());
                dataModelComponent.setOutputComponentId(dataModelComponent.getInputComponentCode() == null ? null : dataComponentMap.get(dataModelComponent.getOutputComponentCode()) == null ? null : dataComponentMap.get(dataModelComponent.getOutputComponentCode()).getComponentId());
                dataModelPrRepository.saveDataModelComponent(dataModelComponent);
            }
            // 重新组装json
            req.getDataModel().setComponentJson(formatModelComponentJson(req.getModelComponentReq(), dataComponentMap));
            req.getDataModel().setIsDraft(ModelStateEnum.SAVE.getStateType());
            req.getDataTask().setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
            Map<String, DataComponentReq> dataComponentReqMap = req.getModelComponentReq().getModelComponents().stream().collect(Collectors.toMap(DataComponentReq::getComponentCode, Function.identity()));
            if (dataComponentReqMap.containsKey("jointStatistical")) {
                req.getDataTask().setTaskType(TaskTypeEnum.JOINT_STATISTICAL.getTaskType());
            }
            dataTaskPrRepository.updateDataTask(req.getDataTask());
            req.getDataModelTask().setComponentJson(JSONObject.toJSONString(req.getDataComponents()));
            dataModelPrRepository.updateDataModelTask(req.getDataModelTask());
            for (DataComponent dataComponent : req.getDataComponents()) {
                if (req.getDataTask().getTaskState().equals(TaskStateEnum.FAIL.getStateType())
                        || req.getDataTask().getTaskState().equals(TaskStateEnum.CANCEL.getStateType())) {
                    break;
                }
                dataComponent.setStartTime(System.currentTimeMillis());
                dataComponent.setComponentState(2);
                req.getDataModelTask().setComponentJson(JSONObject.toJSONString(req.getDataComponents()));
                dataModelPrRepository.updateDataModelTask(req.getDataModelTask());
                executeBeanMethod(false, dataComponentReqMap.get(dataComponent.getComponentCode()), req);
                if (req.getDataTask().getTaskState().equals(TaskStateEnum.FAIL.getStateType())) {
                    dataComponent.setComponentState(3);
                } else {
                    dataComponent.setComponentState(1);
                }
                dataComponent.setEndTime(System.currentTimeMillis());
                req.getDataModelTask().setComponentJson(JSONObject.toJSONString(req.getDataComponents()));
                dataModelPrRepository.updateDataModelTask(req.getDataModelTask());
            }
        } catch (Exception e) {
            req.getDataTask().setTaskState(TaskStateEnum.FAIL.getStateType());
            log.info(e.getMessage());
            e.printStackTrace();
        }
        req.getDataTask().setTaskEndTime(System.currentTimeMillis());
        updateTaskState(req.getDataTask());
        log.info("end model task grpc modelId:{} modelName:{} end time:{}", req.getDataModel().getModelId(), req.getDataModel().getModelName(), System.currentTimeMillis());
        log.info("Share model task modelId:{} modelName:{}", req.getDataModel().getModelId(), req.getDataModel().getModelName());
        ShareModelVo vo = new ShareModelVo();
        vo.setDataModel(req.getDataModel());
        vo.setDataTask(req.getDataTask());
        vo.setDataModelTask(req.getDataModelTask());
        vo.setDmrList(req.getDmrList());
        vo.setShareOrganId(req.getResourceList().stream().map(ModelProjectResourceVo::getOrganId).collect(Collectors.toList()));
        vo.setDerivationList(req.getDerivationList());
        sendShareModelTask(vo);
        sendModelTaskMail(req.getDataTask(), req.getDataModel().getProjectId());
        dataProjectPrRepository.updateDataProject(dataProjectRepository.selectDataProjectByProjectId(req.getDataModel().getProjectId(), null));
    }

    private String formatModelComponentJson(DataModelAndComponentReq params, Map<String, DataComponent> dataComponentMap) {
        for (DataComponentReq modelComponent : params.getModelComponents()) {
            modelComponent.setComponentId(dataComponentMap.get(modelComponent.getComponentCode()).getComponentId().toString());
            for (DataComponentRelationReq req : modelComponent.getInput()) {
                req.setComponentId(dataComponentMap.get(req.getComponentCode()).getComponentId().toString());
            }
            for (DataComponentRelationReq req : modelComponent.getOutput()) {
                req.setComponentId(dataComponentMap.get(req.getComponentCode()).getComponentId().toString());
            }
        }
        return JSONObject.toJSONString(params);
    }


    @Async
    public void psiGrpcRun(DataPsiTask psiTask, DataPsi dataPsi,String taskName) {
        DataResource ownDataResource = dataResourceRepository.queryDataResourceByResourceFusionId(dataPsi.getOwnResourceId());
        if (ownDataResource==null && StringUtils.isNumeric(dataPsi.getOwnResourceId())){
            ownDataResource = dataResourceRepository.queryDataResourceById(Long.parseLong(dataPsi.getOwnResourceId()));
        }
        String resourceId, resourceColumnNameList;
        int available;
        // Resolve other resource by fusion-id first (cross-org refs are UUIDs), fall back to numeric id.
        DataResource otherDataResource = dataResourceRepository.queryDataResourceByResourceFusionId(dataPsi.getOtherResourceId());
        if (otherDataResource == null && StringUtils.isNumeric(dataPsi.getOtherResourceId())) {
            otherDataResource = dataResourceRepository.queryDataResourceById(Long.parseLong(dataPsi.getOtherResourceId()));
        }
        // 跨机构回退：对方公开资源可能未同步进本地 data_resource(隔离 fusion / 离线部署)。
        // 本地查不到时，改从 fusion 中心(otherBusinessesService.getDataResource)拉取元数据，
        // 使跨机构 PSI 不因本地缺失而直接失败。下游只用到 fusionId/列名/状态三项。
        if (otherDataResource == null) {
            try {
                BaseResultEntity fusionRes = otherBusinessesService.getDataResource(dataPsi.getOtherResourceId());
                if (fusionRes != null && fusionRes.getCode() == 0 && fusionRes.getResult() != null) {
                    DataResourceCopyVo copyVo = JSONObject.parseObject(JSON.toJSONString(fusionRes.getResult()), DataResourceCopyVo.class);
                    if (copyVo != null && StringUtils.isNotBlank(copyVo.getResourceColumnNameList())) {
                        otherDataResource = new DataResource();
                        otherDataResource.setResourceFusionId(StringUtils.isNotBlank(copyVo.getResourceId()) ? copyVo.getResourceId() : dataPsi.getOtherResourceId());
                        otherDataResource.setFileHandleField(copyVo.getResourceColumnNameList());
                        otherDataResource.setResourceState(copyVo.getResourceState() == null ? 0 : copyVo.getResourceState());
                        log.info("Resolved other resource via fusion center for resourceId: {}", dataPsi.getOtherResourceId());
                    }
                }
            } catch (Exception e) {
                log.error("Cross-org fetch of other resource failed for resourceId: {}", dataPsi.getOtherResourceId(), e);
            }
        }
        if (otherDataResource == null) {
            log.error("Failed to query other resource from local database for resourceId: {}", dataPsi.getOtherResourceId());
            psiTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataPsiPrRepository.updateDataPsiTask(psiTask);
            return;
        }
        resourceId = StringUtils.isNotBlank(otherDataResource.getResourceFusionId()) ? otherDataResource.getResourceFusionId() : otherDataResource.getResourceId().toString();
        resourceColumnNameList = otherDataResource.getFileHandleField();
        available = otherDataResource.getResourceState();
        DataTask dataTask = new DataTask();
        dataTask.setTaskIdName(psiTask.getTaskId());
        if (taskName == null){
            dataTask.setTaskName(dataPsi.getResultName());
        }else {
            dataTask.setTaskName(taskName);
        }
        dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataTask.setTaskType(TaskTypeEnum.PSI.getTaskType());
        dataTask.setTaskStartTime(System.currentTimeMillis());
        dataTaskPrRepository.saveDataTask(dataTask);
        String teeResourceId = "";
        if (dataPsi.getTag().equals(2)){
            DataFResourceReq fresourceReq = new DataFResourceReq();
            fresourceReq.setOrganId(dataPsi.getTeeOrganId());
            BaseResultEntity resourceList = otherBusinessesService.getResourceList(fresourceReq);
            if (resourceList.getCode()!=0) {
                psiTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataPsiPrRepository.updateDataPsiTask(psiTask);
                dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataTask.setTaskEndTime(System.currentTimeMillis());
                dataTask.setTaskErrorMsg("TEE 机构资源查询失败:"+resourceList.getMsg());
                dataTaskPrRepository.updateDataTask(dataTask);
                return;
            }
            LinkedHashMap<String,Object> data = (LinkedHashMap<String,Object>)resourceList.getResult();
            List<LinkedHashMap<String,Object>> resourceDataList = (List<LinkedHashMap<String,Object>>)data.get("data");
            if (resourceDataList==null || resourceDataList.size()==0) {
                psiTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataPsiPrRepository.updateDataPsiTask(psiTask);
                dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataTask.setTaskEndTime(System.currentTimeMillis());
                dataTask.setTaskErrorMsg("TEE 机构资源查询失败:机构下无资源信息");
                dataTaskPrRepository.updateDataTask(dataTask);
                return;
            }
            teeResourceId = resourceDataList.get(0).get("resourceId").toString();
        }
        psiTask.setTaskState(2);
        dataPsiPrRepository.updateDataPsiTask(psiTask);
        log.info("psi available:{}", available);
        if (true) {  // Force PSI execution regardless of available flag
            Date date = new Date();
            StringBuilder sb = new StringBuilder().append(baseConfiguration.getResultUrlDirPrefix()).append(DateUtil.formatDate(date, DateUtil.DateStyle.HOUR_FORMAT_SHORT.getFormat())).append("/").append(psiTask.getTaskId()).append(".csv");
            psiTask.setFilePath(sb.toString());
            try {
                TaskPSIParam psiParam = new TaskPSIParam();
                psiParam.setPsiTag(dataPsi.getTag());
                psiParam.setPsiType(dataPsi.getOutputContent());
                psiParam.setClientData(ownDataResource.getResourceFusionId());
                List<String> clientFields = Arrays.asList(ownDataResource.getFileHandleField().split(","));
                List<String> ownKeyword = Arrays.asList(dataPsi.getOwnKeyword().split(","));
                psiParam.setClientIndex(ownKeyword.stream().map(clientFields::indexOf).toArray(Integer[]::new));
                List<String> serverFields = Arrays.asList(resourceColumnNameList.split(","));
                List<String> otherKeyword = Arrays.asList(dataPsi.getOtherKeyword().split(","));
                psiParam.setServerData(resourceId);
                psiParam.setTeeData(teeResourceId);
                psiParam.setServerIndex(otherKeyword.stream().map(serverFields::indexOf).toArray(Integer[]::new));
                psiParam.setOutputFullFilename(psiTask.getFilePath());
                TaskParam taskParam = new TaskParam();
                taskParam.setTaskId(dataTask.getTaskIdName());
                taskParam.setTaskContentParam(psiParam);
                taskHelper.submit(taskParam);
                if (taskParam.getSuccess()){
                    dataTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
                }else {
                    dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                    dataTask.setTaskErrorMsg(taskParam.getError());
                }
                if (!dataTask.getTaskState().equals(TaskStateEnum.CANCEL.getStateType()) && !dataTask.getTaskState().equals(TaskStateEnum.FAIL.getStateType())) {
                    if (!FileUtil.isFileExists(psiTask.getFilePath())) {
                        dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                    }
                }
            } catch (Exception e) {
                dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                log.info("grpc Exception:{}", e.getMessage());
                e.printStackTrace();
            }
        } else {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
        }
        // data_psi_task.task_state 约定(与前端 PSI/list.vue + DataPsiService 一致):
        //   0未开始 1成功 2运行中 3失败 4取消。成功必须置 1(前端 1=成功可下载/可删除;
        //   若置 2 会被前端渲染成「运行中」永久转圈、delPsiTask 报「运行中无法删除」、
        //   结果不可下载)。历史误置为 2 是本 bug 的根因。运行中(line ~300)才用 2。
        if (dataTask.getTaskState().equals(TaskStateEnum.SUCCESS.getStateType())) {
            psiTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());  // =1 成功
            // Read result file content and row count
            String fileContent = FileUtil.getFileContent(psiTask.getFilePath());
            if (fileContent != null) {
                psiTask.setFileContent(fileContent);
                String[] lines = fileContent.split("\n");
                int rowCount = 0;
                for (String line : lines) { if (!line.trim().isEmpty()) rowCount++; }
                psiTask.setFileRows(rowCount);
            }
        } else {
            psiTask.setTaskState(dataTask.getTaskState());
        }
        dataPsiPrRepository.updateDataPsiTask(psiTask);
        dataTask.setTaskEndTime(System.currentTimeMillis());
        updateTaskState(dataTask);
    }

    public FutureTask<TaskParam<TaskPIRParam>> getPirTaskFutureTask(DataPirKeyQuery dataPirKeyQuery,DataTask dataTask, DataPirTask dataPirTask,String resourceColumnNames,String formatDate,int job){
        FutureTask<TaskParam<TaskPIRParam>> pirTaskFutureTask = new FutureTask<>(new Callable<TaskParam<TaskPIRParam>>() {
            @Override
            public TaskParam<TaskPIRParam> call() throws Exception {
                StringBuffer sb = new StringBuffer().append(baseConfiguration.getResultUrlDirPrefix())
                        .append(formatDate).append("/").append(SnowflakeId.getInstance().nextId()).append(".csv");
                TaskParam<TaskPIRParam> taskParam = new TaskParam(new TaskPIRParam());
                taskParam.setTaskId(dataTask.getTaskIdName());
                taskParam.setJobId(String.valueOf(job));
                // 查询目标值，同组查询目标值使用逗号的字符串隔开
                String[] querys = new String[dataPirKeyQuery.getQuery().size()];
                for (int i = 0; i < dataPirKeyQuery.getQuery().size(); i++) {
                    querys[i] = String.join(",", dataPirKeyQuery.getQuery().get(i));
                }
                taskParam.getTaskContentParam().setQueryParam(querys);
                taskParam.getTaskContentParam().setServerData(dataPirTask.getResourceId());
                taskParam.getTaskContentParam().setOutputFullFilename(sb.toString());
                // 关键词/匿踪查询走 APSI(PirType.KEY_PIR=1)：本平台的 PIR 是按 keyColumns 的
                // **键值**检索(pirParam 是键值而非行下标)，对应 node 的 APSI 算子(有
                // pir_server_config.json)。原硬编码 0=ID_PIR(SealPIR 索引 PIR)在 node 上
                // `Pir init operator failed`(2026-09-07 实测)——它期望的是行下标、且本部署未配
                // SealPIR 参数。改为 1 后 node 走 APSI 关键词 PIR，跨机构匿踪查询可跑通。
                taskParam.getTaskContentParam().setPirType(1);
                List<String> columns = Arrays.asList(resourceColumnNames.split(","));
                List<String> keyColumns = Arrays.asList(dataPirKeyQuery.getKey());
                Integer[] keyIdx = keyColumns.stream().map(columns::indexOf).toArray(Integer[]::new);
                taskParam.getTaskContentParam().setKeyColumns(keyIdx);
                // label_columns: all columns except key columns
                Integer[] labelIdx = java.util.stream.IntStream.range(0, columns.size())
                    .filter(i -> !Arrays.asList(keyIdx).contains(i))
                    .boxed().toArray(Integer[]::new);
                taskParam.getTaskContentParam().setLabelColumns(labelIdx);
                taskHelper.submit(taskParam);
                if (taskParam.getSuccess()){
                    dataRedisRepository.pirTaskResultHandle(dataTask.getTaskIdName(),CsvUtil.csvReader(sb.toString(), null));
                    Files.delete(Paths.get(sb.toString()));
                }
                return taskParam;
            }
        });
        return pirTaskFutureTask;
    }

    @Async
    public void pirGrpcTask(DataTask dataTask, DataPirTask dataPirTask,String resourceColumnNames, List<DataPirKeyQuery> dataPirKeyQueries) {
        Date date = new Date();
        try {
            dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
            updateTaskState(dataTask);
            String formatDate = DateUtil.formatDate(date, DateUtil.DateStyle.HOUR_FORMAT_SHORT.getFormat());
            StringBuilder sb = new StringBuilder().append(baseConfiguration.getResultUrlDirPrefix()).append(formatDate).append("/").append(dataTask.getTaskIdName()).append(".csv");
            dataTask.setTaskResultPath(sb.toString());
//            List<DataPirKeyQuery> dataPirKeyQueries = JSONArray.parseArray(dataPirTask.getRetrievalId(), DataPirKeyQuery.class);
            Map<String,String> jobMap = new HashMap<>();
            List<FutureTask<TaskParam<TaskPIRParam>>> futureTasks = new ArrayList<>();
            // 条件组，默认只有一个
            for (int i = 0; i < dataPirKeyQueries.size(); i++) {
                FutureTask<TaskParam<TaskPIRParam>> pirTaskFutureTask = getPirTaskFutureTask(dataPirKeyQueries.get(i), dataTask, dataPirTask, resourceColumnNames, formatDate, i);
                primaryThreadPool.submit(pirTaskFutureTask);
                futureTasks.add(pirTaskFutureTask);
                jobMap.put(i+"",String.join("+",dataPirKeyQueries.get(i).getKey()));
            }
            List<TaskParam<TaskPIRParam>> listTaskParams = new ArrayList<>();
            for (FutureTask<TaskParam<TaskPIRParam>> futureTask : futureTasks) {
                listTaskParams.add(futureTask.get());
            }
            for (TaskParam<TaskPIRParam> listTaskParam : listTaskParams) {
                if (dataTask.getTaskState().equals(TaskStateEnum.FAIL.getStateType())){
                    if (!listTaskParam.getSuccess()){
                        dataTask.setTaskErrorMsg("\n【"+jobMap.get(listTaskParam.getJobId())+"】匹配规则出错:"+listTaskParam.getError());
                    }
                }
                if (!listTaskParam.getSuccess()){
                    dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                    dataTask.setTaskErrorMsg("\n【"+jobMap.get(listTaskParam.getJobId())+"】匹配规则出错:"+listTaskParam.getError());
                }else {
                    dataTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
                }
            }
            if (dataTask.getTaskState().equals(TaskStateEnum.SUCCESS.getStateType())){
                List<String> pirTaskResultData = dataRedisRepository.getPirTaskResultData(dataTask.getTaskIdName());
//                log.info("数据写入文件sb:{} -  pirTaskResultDataSize:{}",sb.toString(),pirTaskResultData.size());
                boolean b = CsvUtil.csvWrite(sb.toString(), pirTaskResultData);
//                log.info("数据写入文件结果:{}",b);

            }
        } catch (Exception e) {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataTask.setTaskErrorMsg(e.getMessage());
            log.info("grpc pirSubmitTask Exception:{}", e.getMessage());
            e.printStackTrace();
        }finally {
            dataRedisRepository.deletePirTaskResultKey(dataTask.getTaskIdName());
        }
        dataTask.setTaskEndTime(System.currentTimeMillis());
        updateTaskState(dataTask);
    }

    public void sendShareModelTask(ShareModelVo shareModelVo) {
        singleTaskChannel.input().send(MessageBuilder.withPayload(JSON.toJSONString(new BaseFunctionHandleEntity(BaseFunctionHandleEnum.SPREAD_MODEL_DATA_TASK.getHandleType(), shareModelVo))).build());
    }

    public void deleteModel(ShareModelVo vo) {
        Long projectId = vo.getDataModel().getProjectId();
        DataProject dataProject = dataProjectRepository.selectDataProjectByProjectId(projectId, null);
        vo.setProjectId(dataProject.getProjectId());
        List<DataProjectOrgan> dataProjectOrgans = dataProjectRepository.selectDataProjcetOrganByProjectId(dataProject.getProjectId());
        vo.setShareOrganId(dataProjectOrgans.stream().map(DataProjectOrgan::getOrganId).collect(Collectors.toList()));
        sendShareModelTask(vo);
    }

    @Async
    public void deleteModelTask(DataTask dataTask) {
        DataModelTask modelTask = dataModelRepository.queryModelTaskById(dataTask.getTaskId());
        DataModel dataModel = dataModelRepository.queryDataModelById(modelTask.getModelId());
        DataProject dataProject = dataProjectRepository.selectDataProjectByProjectId(dataModel.getProjectId(), null);
        ShareModelVo vo = new ShareModelVo(dataProject);
        vo.setDataTask(dataTask);
        vo.setDataModelTask(modelTask);
        dataModel.setIsDel(1);
        vo.setDataModel(dataModel);
        List<DataProjectOrgan> dataProjectOrgans = dataProjectRepository.selectDataProjcetOrganByProjectId(dataProject.getProjectId());
        vo.setShareOrganId(dataProjectOrgans.stream().map(DataProjectOrgan::getOrganId).collect(Collectors.toList()));
        sendShareModelTask(vo);
    }


    /**
     * 运行推理
     *
     * @param dataReasoning             推理
     * @param dataReasoningResourceList 推理资源
     * @param modelTask                 推理所得
     */
    @Async
    public void runReasoning(DataReasoning dataReasoning, List<DataReasoningResource> dataReasoningResourceList, DataModelTask modelTask) {
        String labelDataset = "";    // 发起者资源
        String guestDataset = "";    // 协助方资源
        for (DataReasoningResource dataReasoningResource : dataReasoningResourceList) {
            if (dataReasoningResource.getParticipationIdentity() == 1) {
                labelDataset = dataReasoningResource.getResourceId();
            } else {
                guestDataset = dataReasoningResource.getResourceId();
            }
        }
        log.info("{}-{}", labelDataset, guestDataset);
        DataTask dataTask = new DataTask();
        dataTask.setTaskIdName(Long.toString(SnowflakeId.getInstance().nextId()));
        dataTask.setTaskName(dataReasoning.getReasoningName());
        dataTask.setTaskStartTime(System.currentTimeMillis());
        dataTask.setTaskType(TaskTypeEnum.REASONING.getTaskType());
        dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataTask.setTaskUserId(dataReasoning.getUserId());
        dataTaskPrRepository.saveDataTask(dataTask);
        dataReasoning.setRunTaskId(dataTask.getTaskId());
        dataReasoning.setReasoningState(dataTask.getTaskState());
        dataReasoningPrRepository.updateDataReasoning(dataReasoning);
        Map<String, Object> map = new HashMap<>();
        map.put(PYTHON_LABEL_DATASET, labelDataset);  // 放入发起方资源
        List<DataComponent> dataComponents = JSONArray.parseArray(modelTask.getComponentJson(), DataComponent.class);
        DataComponent model = dataComponents.stream().filter(dataComponent -> "model".equals(dataComponent.getComponentCode())).findFirst().orElse(null);
        if (model == null) {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataTask.setTaskErrorMsg("未能获取到模型信息");
        } else {
            List<DataComponentValue> dataComponentValue = JSONArray.parseArray(model.getDataJson(), DataComponentValue.class);
            DataComponentValue modelType = dataComponentValue.stream().filter(d -> "modelType".equals(d.getKey())).findFirst().orElse(null);
            if (modelType == null || StringUtils.isBlank(modelType.getVal())) {
                dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataTask.setTaskErrorMsg("未能获取到模型类型信息");
            } else {
                ModelTypeEnum modelTypeEnum = ModelTypeEnum.MODEL_TYPE_MAP.get(Integer.valueOf(modelType.getVal()));
                if (modelTypeEnum==null){
                    dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                    dataTask.setTaskErrorMsg("未能匹配到模型类型信息");
                }else {
                    map.put(PYTHON_GUEST_DATASET, guestDataset);  // 放入合作方资源
                    grpc(dataReasoning, dataTask, modelTypeEnum, map);
                }
            }
        }
    }

    public void sendModelTaskMail(DataTask dataTask, Long projectId) {
        if (!dataTask.getTaskState().equals(TaskStateEnum.FAIL.getStateType())) {
            return;
        }
        if (StringUtils.isBlank(baseConfiguration.getTaskEmailSubject())) {
            return;
        }
        SysUser sysUser = sysUserSecondarydbRepository.selectSysUserByUserId(dataTask.getTaskUserId());
        if (sysUser == null) {
            log.info("task_id:{} The task email was not sent. Reason for not sending : No user information", dataTask.getTaskIdName());
            return;
        }
        if (!DataUtil.isEmail(sysUser.getUserAccount())) {
            log.info("task_id:{} The task email was not sent. Reason for not sending : The user account is not an email address", dataTask.getTaskIdName());
            return;
        }
        StringBuilder sb = new StringBuilder();
        sb.append("尊敬的【");
        sb.append(sysUser.getUserName());
        sb.append("】您在【");
        sb.append(DateUtil.formatDate(dataTask.getCreateDate(), DateUtil.DateStyle.TIME_FORMAT_NORMAL.getFormat()));
        sb.append("】使用【");
        sb.append(sysUser.getUserAccount());
        sb.append("】创建的任务已失败\n");
        if (StringUtils.isNotBlank(dataTask.getTaskName())) {
            sb.append("任务名称：【").append(dataTask.getTaskName()).append("】\n");
        }
        sb.append("任务ID：【").append(dataTask.getTaskIdName()).append("】\n");
        if (StringUtils.isNotBlank(baseConfiguration.getSystemDomainName())) {
            sb.append("<a href=\"").append(baseConfiguration.getSystemDomainName()).append("/#/project/detail/").append(projectId).append("/task/").append(dataTask.getTaskId());
            sb.append("\">").append("点击查询任务详情").append("</a>");
        }
        sysEmailService.send(sysUser.getUserAccount(), baseConfiguration.getTaskEmailSubject(), sb.toString());
    }

    public void updateTaskState(DataTask dataTask) {
        DataTask rawDataTask = dataTaskRepository.selectDataTaskByTaskId(dataTask.getTaskId());
        if (rawDataTask != null && rawDataTask.getTaskState().equals(TaskStateEnum.CANCEL.getStateType())) {
            dataTask.setTaskState(TaskStateEnum.CANCEL.getStateType());
        } else {
            dataTaskPrRepository.updateDataTask(dataTask);
        }
    }

    private void grpc(DataReasoning dataReasoning, DataTask dataTask, ModelTypeEnum modelTypeEnum, Map<String, Object> map) {
        // 推理任务
        DataTask modelTask = dataTaskRepository.selectDataTaskByTaskId(dataReasoning.getTaskId());
        // 推理模板参数
        ModelOutputPathDto modelOutputPathDto = JSONObject.parseObject(modelTask.getTaskResultContent(), ModelOutputPathDto.class);
        map.put("indicatorFileName", modelOutputPathDto.getIndicatorFileName());
        map.put("guestModelFileName", modelOutputPathDto.getGuestModelFileName());
        map.put("hostModelFileName", modelOutputPathDto.getHostModelFileName());
        map.put("guestLookupTable", modelOutputPathDto.getGuestLookupTable());
        map.put("hostLookupTable", modelOutputPathDto.getHostLookupTable());
        map.put("predictFileName", modelOutputPathDto.getPredictFileName());
        try {
            TaskParam<TaskComponentParam> taskParam = new TaskParam<>(new TaskComponentParam());
            taskParam.setTaskId(dataTask.getTaskIdName());
            taskParam.setJobId("1");
            taskParam.getTaskContentParam().setModelType(modelTypeEnum);
            taskParam.getTaskContentParam().setInfer(true);
            taskParam.getTaskContentParam().setFreemarkerMap(map);
            log.info(taskParam.toString());
            taskHelper.submit(taskParam);
            if (taskParam.getSuccess()){
                dataTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
                dataTask.setTaskResultPath(modelOutputPathDto.getPredictFileName());
                dataReasoning.setReleaseDate(new Date());
            }else {
                dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
                dataTask.setTaskErrorMsg("运行失败:"+taskParam.getError());
            }
        } catch (Exception e) {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataTask.setTaskErrorMsg(e.getMessage());
            log.info("grpc Exception:{}", e.getMessage());
            e.printStackTrace();
        }
        dataReasoning.setReasoningState(dataTask.getTaskState());
        dataTask.setTaskEndTime(System.currentTimeMillis());
        dataTaskPrRepository.updateDataTask(dataTask);
        dataReasoningPrRepository.updateDataReasoning(dataReasoning);
    }

    // ==================== 联邦求差 / 联邦求并 执行层 ====================
    // 复用 PSI 引擎链路(psiType=1 即差集，语义 = client − server，与 DataPsi.outputContent 一致)。
    // 求并没有引擎原生算子，由「本方 keyword 全量 ∪ (对方 − 本方)」组合而成 —— 求并结果本就要
    // 揭示两方元素给结果方，该组合不产生额外信息泄露。

    /**
     * 联邦求差：direction 0 = 本方−对方(A−B，client=本方)，1 = 对方−本方(B−A，client=对方)。
     * 任务状态约定同 data_psi_task：0未开始 1成功 2运行中 3失败 4取消。
     */
    @Async
    public void differenceGrpcRun(DataDifferenceTask diffTask, DataDifference dataDifference) {
        DataTask dataTask = new DataTask();
        dataTask.setTaskIdName(diffTask.getTaskId());
        dataTask.setTaskName(dataDifference.getResultName());
        dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataTask.setTaskType(TaskTypeEnum.DIFFERENCE.getTaskType());
        dataTask.setTaskStartTime(System.currentTimeMillis());
        dataTaskPrRepository.saveDataTask(dataTask);
        diffTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataDifferencePrRepository.updateDataDifferenceTask(diffTask);
        String errorMsg = null;
        try {
            DataResource own = resolveResourceWithFusionFallback(dataDifference.getOwnResourceId());
            DataResource other = resolveResourceWithFusionFallback(dataDifference.getOtherResourceId());
            if (own == null) {
                errorMsg = "本方资源查询失败:" + dataDifference.getOwnResourceId();
            } else if (other == null) {
                errorMsg = "对方资源查询失败:" + dataDifference.getOtherResourceId();
            }
            String teeResourceId = "";
            if (errorMsg == null && Integer.valueOf(2).equals(dataDifference.getTag())) {
                teeResourceId = resolveTeeResourceId(dataDifference.getTeeOrganId());
                if (teeResourceId == null) {
                    errorMsg = "TEE 机构资源查询失败:" + dataDifference.getTeeOrganId();
                }
            }
            if (errorMsg == null) {
                String outputPath = new StringBuilder().append(baseConfiguration.getResultUrlDirPrefix())
                        .append(DateUtil.formatDate(new Date(), DateUtil.DateStyle.HOUR_FORMAT_SHORT.getFormat()))
                        .append("/").append(diffTask.getTaskId()).append(".csv").toString();
                diffTask.setFilePath(outputPath);
                boolean reverse = Integer.valueOf(1).equals(dataDifference.getDifferenceDirection());
                if (reverse) {
                    errorMsg = runEnginePsiDifference(diffTask.getTaskId(), dataDifference.getTag(), teeResourceId,
                            engineResourceId(other), dataDifference.getOtherKeyword(), other.getFileHandleField(),
                            engineResourceId(own), dataDifference.getOwnKeyword(), own.getFileHandleField(), outputPath);
                } else {
                    errorMsg = runEnginePsiDifference(diffTask.getTaskId(), dataDifference.getTag(), teeResourceId,
                            engineResourceId(own), dataDifference.getOwnKeyword(), own.getFileHandleField(),
                            engineResourceId(other), dataDifference.getOtherKeyword(), other.getFileHandleField(), outputPath);
                }
            }
        } catch (Exception e) {
            log.error("differenceGrpcRun taskId:{}", diffTask.getTaskId(), e);
            errorMsg = "执行异常:" + e.getMessage();
        }
        if (errorMsg == null) {
            dataTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
            diffTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
            String fileContent = FileUtil.getFileContent(diffTask.getFilePath());
            if (fileContent != null) {
                diffTask.setFileContent(fileContent);
                diffTask.setFileRows(countNonEmptyLines(fileContent));
            }
        } else {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataTask.setTaskErrorMsg(errorMsg);
            diffTask.setTaskState(TaskStateEnum.FAIL.getStateType());
        }
        dataDifferencePrRepository.updateDataDifferenceTask(diffTask);
        dataTask.setTaskEndTime(System.currentTimeMillis());
        updateTaskState(dataTask);
        logManagementService.finishComputeLogByTaskId(diffTask.getTaskId(), errorMsg == null ? 1 : 2, errorMsg);
    }

    /**
     * 联邦求并：A ∪ B = 本方 keyword 全量 ∪ (对方 − 本方)。
     * 先经引擎跑 (对方 − 本方) 差集，再与本方 keyword 列本地合并去重。
     */
    @Async
    public void unionGrpcRun(DataUnionTask unionTask, DataUnion dataUnion) {
        DataTask dataTask = new DataTask();
        dataTask.setTaskIdName(unionTask.getTaskId());
        dataTask.setTaskName(dataUnion.getResultName());
        dataTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataTask.setTaskType(TaskTypeEnum.UNION.getTaskType());
        dataTask.setTaskStartTime(System.currentTimeMillis());
        dataTaskPrRepository.saveDataTask(dataTask);
        unionTask.setTaskState(TaskStateEnum.IN_OPERATION.getStateType());
        dataUnionPrRepository.updateDataUnionTask(unionTask);
        String errorMsg = null;
        String diffPath = null;
        try {
            DataResource own = resolveResourceWithFusionFallback(dataUnion.getOwnResourceId());
            DataResource other = resolveResourceWithFusionFallback(dataUnion.getOtherResourceId());
            if (own == null) {
                errorMsg = "本方资源查询失败:" + dataUnion.getOwnResourceId();
            } else if (other == null) {
                errorMsg = "对方资源查询失败:" + dataUnion.getOtherResourceId();
            } else if (StringUtils.isBlank(own.getUrl())) {
                errorMsg = "本方资源文件路径为空，无法合并求并结果";
            }
            String teeResourceId = "";
            if (errorMsg == null && Integer.valueOf(2).equals(dataUnion.getTag())) {
                teeResourceId = resolveTeeResourceId(dataUnion.getTeeOrganId());
                if (teeResourceId == null) {
                    errorMsg = "TEE 机构资源查询失败:" + dataUnion.getTeeOrganId();
                }
            }
            if (errorMsg == null) {
                String dir = new StringBuilder().append(baseConfiguration.getResultUrlDirPrefix())
                        .append(DateUtil.formatDate(new Date(), DateUtil.DateStyle.HOUR_FORMAT_SHORT.getFormat()))
                        .append("/").toString();
                diffPath = dir + unionTask.getTaskId() + "-diff.csv";
                String outputPath = dir + unionTask.getTaskId() + ".csv";
                unionTask.setFilePath(outputPath);
                // 引擎跑 (对方 − 本方)：client=对方，server=本方，psiType=1
                errorMsg = runEnginePsiDifference(unionTask.getTaskId(), dataUnion.getTag(), teeResourceId,
                        engineResourceId(other), dataUnion.getOtherKeyword(), other.getFileHandleField(),
                        engineResourceId(own), dataUnion.getOwnKeyword(), own.getFileHandleField(), diffPath);
                if (errorMsg == null) {
                    errorMsg = buildUnionResult(own, dataUnion.getOwnKeyword(), diffPath, outputPath);
                }
            }
        } catch (Exception e) {
            log.error("unionGrpcRun taskId:{}", unionTask.getTaskId(), e);
            errorMsg = "执行异常:" + e.getMessage();
        } finally {
            if (diffPath != null) {
                try { Files.deleteIfExists(Paths.get(diffPath)); } catch (Exception ignore) { }
            }
        }
        if (errorMsg == null) {
            dataTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
            unionTask.setTaskState(TaskStateEnum.SUCCESS.getStateType());
            String fileContent = FileUtil.getFileContent(unionTask.getFilePath());
            if (fileContent != null) {
                unionTask.setFileContent(fileContent);
                unionTask.setFileRows(countNonEmptyLines(fileContent));
            }
        } else {
            dataTask.setTaskState(TaskStateEnum.FAIL.getStateType());
            dataTask.setTaskErrorMsg(errorMsg);
            unionTask.setTaskState(TaskStateEnum.FAIL.getStateType());
        }
        dataUnionPrRepository.updateDataUnionTask(unionTask);
        dataTask.setTaskEndTime(System.currentTimeMillis());
        updateTaskState(dataTask);
        logManagementService.finishComputeLogByTaskId(unionTask.getTaskId(), errorMsg == null ? 1 : 2, errorMsg);
    }

    /**
     * 资源解析：本地 fusionId → 本地数值 id → fusion 中心兜底(跨机构公开资源可能未同步进本地库)。
     */
    private DataResource resolveResourceWithFusionFallback(String resourceId) {
        if (StringUtils.isBlank(resourceId)) {
            return null;
        }
        DataResource res = dataResourceRepository.queryDataResourceByResourceFusionId(resourceId);
        if (res == null && StringUtils.isNumeric(resourceId)) {
            res = dataResourceRepository.queryDataResourceById(Long.parseLong(resourceId));
        }
        if (res == null) {
            try {
                BaseResultEntity fusionRes = otherBusinessesService.getDataResource(resourceId);
                if (fusionRes != null && fusionRes.getCode() == 0 && fusionRes.getResult() != null) {
                    DataResourceCopyVo copyVo = JSONObject.parseObject(JSON.toJSONString(fusionRes.getResult()), DataResourceCopyVo.class);
                    if (copyVo != null && StringUtils.isNotBlank(copyVo.getResourceColumnNameList())) {
                        res = new DataResource();
                        res.setResourceFusionId(StringUtils.isNotBlank(copyVo.getResourceId()) ? copyVo.getResourceId() : resourceId);
                        res.setFileHandleField(copyVo.getResourceColumnNameList());
                        res.setResourceState(copyVo.getResourceState() == null ? 0 : copyVo.getResourceState());
                        log.info("Resolved resource via fusion center: {}", resourceId);
                    }
                }
            } catch (Exception e) {
                log.error("fusion center resource lookup failed: {}", resourceId, e);
            }
        }
        return res;
    }

    private String engineResourceId(DataResource resource) {
        return StringUtils.isNotBlank(resource.getResourceFusionId())
                ? resource.getResourceFusionId() : String.valueOf(resource.getResourceId());
    }

    /** TEE 模式下取可信机构首个资源 id，失败返回 null(同 psiGrpcRun 的 TEE 分支)。 */
    private String resolveTeeResourceId(String teeOrganId) {
        try {
            DataFResourceReq fresourceReq = new DataFResourceReq();
            fresourceReq.setOrganId(teeOrganId);
            BaseResultEntity resourceList = otherBusinessesService.getResourceList(fresourceReq);
            if (resourceList.getCode() != 0) {
                return null;
            }
            LinkedHashMap<String, Object> data = (LinkedHashMap<String, Object>) resourceList.getResult();
            List<LinkedHashMap<String, Object>> resourceDataList = (List<LinkedHashMap<String, Object>>) data.get("data");
            if (resourceDataList == null || resourceDataList.isEmpty()) {
                return null;
            }
            return resourceDataList.get(0).get("resourceId").toString();
        } catch (Exception e) {
            log.error("resolveTeeResourceId failed: {}", teeOrganId, e);
            return null;
        }
    }

    /**
     * 经引擎跑一轮 PSI 差集(client − server)，结果写 outputPath。返回 null=成功，否则为错误信息。
     */
    private String runEnginePsiDifference(String taskIdName, Integer psiTag, String teeResourceId,
                                          String clientDataId, String clientKeyword, String clientColumns,
                                          String serverDataId, String serverKeyword, String serverColumns,
                                          String outputPath) {
        try {
            TaskPSIParam psiParam = new TaskPSIParam();
            psiParam.setPsiTag(psiTag == null ? 0 : psiTag);
            psiParam.setPsiType(1);
            psiParam.setClientData(clientDataId);
            List<String> clientFields = Arrays.asList(clientColumns.split(","));
            Integer[] clientIndex = Arrays.stream(clientKeyword.split(",")).map(clientFields::indexOf).toArray(Integer[]::new);
            if (Arrays.asList(clientIndex).contains(-1)) {
                return "关键字段不在资源列中:" + clientKeyword;
            }
            psiParam.setClientIndex(clientIndex);
            psiParam.setServerData(serverDataId);
            List<String> serverFields = Arrays.asList(serverColumns.split(","));
            Integer[] serverIndex = Arrays.stream(serverKeyword.split(",")).map(serverFields::indexOf).toArray(Integer[]::new);
            if (Arrays.asList(serverIndex).contains(-1)) {
                return "关键字段不在资源列中:" + serverKeyword;
            }
            psiParam.setServerIndex(serverIndex);
            psiParam.setTeeData(teeResourceId == null ? "" : teeResourceId);
            psiParam.setOutputFullFilename(outputPath);
            TaskParam taskParam = new TaskParam();
            taskParam.setTaskId(taskIdName);
            taskParam.setTaskContentParam(psiParam);
            taskHelper.submit(taskParam);
            if (!taskParam.getSuccess()) {
                return StringUtils.isBlank(taskParam.getError()) ? "引擎执行失败" : taskParam.getError();
            }
            if (!FileUtil.isFileExists(outputPath)) {
                return "引擎结果文件未生成";
            }
            return null;
        } catch (Exception e) {
            log.error("runEnginePsiDifference taskId:{}", taskIdName, e);
            return "引擎执行异常:" + e.getMessage();
        }
    }

    /**
     * 合并求并结果：本方 keyword 列全量(读本方资源文件) ∪ 引擎差集(对方−本方)，去重后写 outputPath。
     * 两侧 CSV 首行均为表头；引擎输出带 UTF-8 BOM，合并前剥掉。
     */
    private String buildUnionResult(DataResource own, String ownKeyword, String diffPath, String outputPath) {
        try {
            List<String> header = Arrays.asList(own.getFileHandleField().split(","));
            List<String> keys = Arrays.asList(ownKeyword.split(","));
            int[] idx = keys.stream().mapToInt(header::indexOf).toArray();
            String ownContent = FileUtil.getFileContent(own.getUrl());
            if (ownContent == null) {
                return "本方资源文件读取失败:" + own.getUrl();
            }
            Set<String> rows = new LinkedHashSet<>();
            String[] ownLines = stripBom(ownContent).split("\n");
            for (int i = 1; i < ownLines.length; i++) {
                String line = ownLines[i].trim();
                if (line.isEmpty()) {
                    continue;
                }
                String[] vals = line.split(",", -1);
                StringBuilder sb = new StringBuilder();
                for (int k = 0; k < idx.length; k++) {
                    if (k > 0) {
                        sb.append(",");
                    }
                    sb.append(idx[k] >= 0 && idx[k] < vals.length ? vals[idx[k]].trim() : "");
                }
                rows.add(sb.toString());
            }
            String diffContent = FileUtil.getFileContent(diffPath);
            if (diffContent != null) {
                String[] diffLines = stripBom(diffContent).split("\n");
                for (int i = 1; i < diffLines.length; i++) {
                    String line = diffLines[i].trim();
                    if (!line.isEmpty()) {
                        rows.add(line);
                    }
                }
            }
            List<String> out = new ArrayList<>();
            out.add(String.join(",", keys));
            out.addAll(rows);
            java.io.File outFile = new java.io.File(outputPath);
            if (outFile.getParentFile() != null) {
                outFile.getParentFile().mkdirs();
            }
            Files.write(Paths.get(outputPath), String.join("\n", out).getBytes(java.nio.charset.StandardCharsets.UTF_8));
            return null;
        } catch (Exception e) {
            log.error("buildUnionResult failed diffPath:{}", diffPath, e);
            return "合并求并结果失败:" + e.getMessage();
        }
    }

    private String stripBom(String content) {
        return content.startsWith("\uFEFF") ? content.substring(1) : content;
    }

    private int countNonEmptyLines(String fileContent) {
        int rowCount = 0;
        for (String line : fileContent.split("\n")) {
            if (!line.trim().isEmpty()) {
                rowCount++;
            }
        }
        return rowCount;
    }
}
