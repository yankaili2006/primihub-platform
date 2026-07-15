package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysApprovalWorkflow;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface SysApprovalWorkflowSecondarydbRepository {
    List<SysApprovalWorkflow> selectList();
    SysApprovalWorkflow selectById(Long id);
}