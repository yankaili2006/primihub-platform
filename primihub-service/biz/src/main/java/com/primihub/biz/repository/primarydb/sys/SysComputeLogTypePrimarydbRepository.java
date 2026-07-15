package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysComputeLogType;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;
@Repository
public interface SysComputeLogTypePrimarydbRepository {
    void insert(SysComputeLogType entity);
    void update(SysComputeLogType entity);
    void delete(@Param("id") Long id);
}