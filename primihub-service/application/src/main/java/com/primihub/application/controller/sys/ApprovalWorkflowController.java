package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveWorkflowParam;
import com.primihub.biz.service.sys.SysApprovalWorkflowService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("approvalWorkflow")
@RestController
public class ApprovalWorkflowController {
    @Autowired private SysApprovalWorkflowService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveWorkflowParam param) {
        if (param.getWorkflowName()==null||"".equals(param.getWorkflowName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"workflowName");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}