package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveWorkflowParam;
import com.primihub.biz.entity.sys.po.SysApprovalWorkflow;
import com.primihub.biz.repository.primarydb.sys.SysApprovalWorkflowPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysApprovalWorkflowSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Slf4j
@Service
public class SysApprovalWorkflowService {
    @Autowired private SysApprovalWorkflowPrimarydbRepository primary;
    @Autowired private SysApprovalWorkflowSecondarydbRepository secondary;
    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }
    public BaseResultEntity save(SaveWorkflowParam param) {
        if (param.getWorkflowName()==null||"".equals(param.getWorkflowName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"workflowName");
        SysApprovalWorkflow entity = new SysApprovalWorkflow();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}