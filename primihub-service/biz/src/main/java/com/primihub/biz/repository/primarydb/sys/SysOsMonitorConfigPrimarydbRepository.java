package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysOsMonitorConfig;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;
@Repository
public interface SysOsMonitorConfigPrimarydbRepository {
    void insert(SysOsMonitorConfig entity);
    void update(SysOsMonitorConfig entity);
    void delete(@Param("id") Long id);
}