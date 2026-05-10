package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.SysConfig;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SysConfigPrimarydbRepository {

    SysConfig selectByGroupAndKey(@Param("configGroup") String configGroup,
                                  @Param("configKey") String configKey);

    List<SysConfig> selectByGroup(@Param("configGroup") String configGroup);

    List<SysConfig> selectAll();

    void insert(SysConfig sysConfig);

    void updateByGroupAndKey(SysConfig sysConfig);

    void deleteByGroup(@Param("configGroup") String configGroup);

    void deleteByGroupAndKey(@Param("configGroup") String configGroup,
                             @Param("configKey") String configKey);
}
