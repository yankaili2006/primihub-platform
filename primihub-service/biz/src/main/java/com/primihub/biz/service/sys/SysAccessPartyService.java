package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveAccessPartyParam;
import com.primihub.biz.entity.sys.po.SysAccessParty;
import com.primihub.biz.repository.primarydb.sys.SysAccessPartyPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysAccessPartySecondarydbRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Service
public class SysAccessPartyService {
    @Autowired private SysAccessPartyPrimarydbRepository primary;
    @Autowired private SysAccessPartySecondarydbRepository secondary;
    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }
    public BaseResultEntity save(SaveAccessPartyParam param) {
        if (param.getPartyName()==null||"".equals(param.getPartyName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"partyName");
        SysAccessParty entity = new SysAccessParty();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}