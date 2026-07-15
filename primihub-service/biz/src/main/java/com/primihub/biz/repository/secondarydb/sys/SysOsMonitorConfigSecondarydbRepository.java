package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysOsMonitorConfig;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface SysOsMonitorConfigSecondarydbRepository {
    List<SysOsMonitorConfig> selectList();
    SysOsMonitorConfig selectById(Long id);
    SysOsMonitorConfig selectByKey(String configKey);
}