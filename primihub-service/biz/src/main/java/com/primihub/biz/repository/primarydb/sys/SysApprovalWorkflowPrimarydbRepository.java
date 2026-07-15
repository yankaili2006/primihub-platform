package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysApprovalWorkflow;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;
@Repository
public interface SysApprovalWorkflowPrimarydbRepository {
    void insert(SysApprovalWorkflow entity);
    void update(SysApprovalWorkflow entity);
    void delete(@Param("id") Long id);
}