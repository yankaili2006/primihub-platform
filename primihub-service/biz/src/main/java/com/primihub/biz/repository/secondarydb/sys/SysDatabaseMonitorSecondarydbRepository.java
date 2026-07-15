package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysDatabaseMonitorConfig;
import java.util.List;
@org.springframework.stereotype.Repository
public interface SysDatabaseMonitorSecondarydbRepository {
    List<SysDatabaseMonitorConfig> selectList();
    SysDatabaseMonitorConfig selectById(Long id);
    List<SysDatabaseMonitorConfig> selectByType(String dbType);
}