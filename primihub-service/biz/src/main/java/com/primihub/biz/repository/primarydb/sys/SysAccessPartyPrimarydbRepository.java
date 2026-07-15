package com.primihub.biz.repository.primarydb.sys;
import com.primihub.biz.entity.sys.po.SysAccessParty;
import org.apache.ibatis.annotations.Param;
@org.springframework.stereotype.Repository
public interface SysAccessPartyPrimarydbRepository {
    void insert(SysAccessParty entity);
    void update(SysAccessParty entity);
    void delete(@Param("id") Long id);
}