package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysComputeLogType;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface SysComputeLogTypeSecondarydbRepository {
    List<SysComputeLogType> selectList();
    SysComputeLogType selectById(Long id);
    SysComputeLogType selectByCode(String typeCode);
}