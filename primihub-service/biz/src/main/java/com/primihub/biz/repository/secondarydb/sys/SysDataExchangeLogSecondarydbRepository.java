package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysDataExchangeLog;
import org.springframework.stereotype.Repository;
import java.util.List;
@Repository
public interface SysDataExchangeLogSecondarydbRepository {
    List<SysDataExchangeLog> selectList();
    SysDataExchangeLog selectById(Long id);
}