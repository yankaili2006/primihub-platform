package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysDatabaseMonitorConfig;
import org.apache.ibatis.annotations.Param;
@org.springframework.stereotype.Repository
public interface SysDatabaseMonitorPrimarydbRepository {
    void insert(SysDatabaseMonitorConfig entity);
    void update(SysDatabaseMonitorConfig entity);
    void delete(@Param("id") Long id);
}