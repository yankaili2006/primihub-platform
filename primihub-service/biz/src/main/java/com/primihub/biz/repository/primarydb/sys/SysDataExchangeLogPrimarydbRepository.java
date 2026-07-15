package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysDataExchangeLog;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;
@Repository
public interface SysDataExchangeLogPrimarydbRepository {
    void insert(SysDataExchangeLog entity);
    void updateSyncStatus(@Param("id") Long id, @Param("syncStatus") Integer syncStatus, @Param("syncMsg") String syncMsg);
    void delete(@Param("id") Long id);
}