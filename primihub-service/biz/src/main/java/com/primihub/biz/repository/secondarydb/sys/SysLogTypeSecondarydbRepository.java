package com.primihub.biz.repository.secondarydb.sys;

import com.primihub.biz.entity.sys.po.SysLogType;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SysLogTypeSecondarydbRepository {
    List<SysLogType> selectLogTypeList();
    SysLogType selectLogTypeById(Long id);
    SysLogType selectLogTypeByCode(String typeCode);
}