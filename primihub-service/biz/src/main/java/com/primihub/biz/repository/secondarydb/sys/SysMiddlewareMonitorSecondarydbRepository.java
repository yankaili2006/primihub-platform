package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysMiddlewareMonitorConfig;
import java.util.List;
@org.springframework.stereotype.Repository
public interface SysMiddlewareMonitorSecondarydbRepository {
    List<SysMiddlewareMonitorConfig> selectList();
    SysMiddlewareMonitorConfig selectById(Long id);
    List<SysMiddlewareMonitorConfig> selectByType(String mwType);
}