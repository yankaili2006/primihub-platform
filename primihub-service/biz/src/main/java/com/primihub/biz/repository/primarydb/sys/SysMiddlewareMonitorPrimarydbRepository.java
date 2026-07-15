package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysMiddlewareMonitorConfig;
import org.apache.ibatis.annotations.Param;
@org.springframework.stereotype.Repository
public interface SysMiddlewareMonitorPrimarydbRepository {
    void insert(SysMiddlewareMonitorConfig entity);
    void update(SysMiddlewareMonitorConfig entity);
    void delete(@Param("id") Long id);
}