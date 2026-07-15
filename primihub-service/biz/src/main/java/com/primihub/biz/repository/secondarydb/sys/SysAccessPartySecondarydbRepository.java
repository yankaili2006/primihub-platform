package com.primihub.biz.repository.secondarydb.sys;
import com.primihub.biz.entity.sys.po.SysAccessParty;
import java.util.List;
@org.springframework.stereotype.Repository
public interface SysAccessPartySecondarydbRepository {
    List<SysAccessParty> selectList();
    SysAccessParty selectById(Long id);
    SysAccessParty selectByCode(String partyCode);
}