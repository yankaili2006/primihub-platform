package com.primihub.biz.service.data.component.impl;

import com.primihub.biz.config.base.ComponentsConfiguration;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.data.po.DataTask;
import com.primihub.biz.entity.data.req.ComponentTaskReq;
import com.primihub.biz.entity.data.req.DataComponentReq;
import com.primihub.biz.service.data.component.ComponentTaskService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service("startComponentTaskServiceImpl")
@Slf4j
public class StartComponentTaskServiceImpl extends BaseComponentServiceImpl implements ComponentTaskService {


    @Autowired
    private ComponentsConfiguration componentsConfiguration;

    @Override
    public BaseResultEntity check(DataComponentReq req,  ComponentTaskReq taskReq) {
        Map<String, String> componentVals = getComponentVals(req.getComponentValues());
        DataTask dataTask = new DataTask();
        if (componentVals.containsKey("taskName")){
            String taskName = componentVals.get("taskName");
            // Truncate task name to 255 characters to fit database column limit
            if (taskName != null && taskName.length() > 255) {
                taskName = taskName.substring(0, 255);
                log.warn("Task name truncated from {} to 255 characters", componentVals.get("taskName").length());
            }
            dataTask.setTaskName(taskName);
        }
        if (componentVals.containsKey("taskDesc")){
            String taskDesc = componentVals.get("taskDesc");
            // Truncate task description to 255 characters to fit database column limit
            if (taskDesc != null && taskDesc.length() > 255) {
                taskDesc = taskDesc.substring(0, 255);
                log.warn("Task description truncated from {} to 255 characters", componentVals.get("taskDesc").length());
            }
            dataTask.setTaskDesc(taskDesc);
        }
        taskReq.setDataTask(dataTask);
        return componentTypeVerification(req,componentsConfiguration.getModelComponents(),taskReq);
    }

    @Override
    public BaseResultEntity runTask(DataComponentReq req, ComponentTaskReq taskReq) {
        return BaseResultEntity.success();
    }
}
