package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveDatabaseMonitorParam;
import com.primihub.biz.entity.sys.po.SysDatabaseMonitorConfig;
import com.primihub.biz.repository.primarydb.sys.SysDatabaseMonitorPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysDatabaseMonitorSecondarydbRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Service
public class SysDatabaseMonitorService {
    @Autowired private SysDatabaseMonitorPrimarydbRepository primary;
    @Autowired private SysDatabaseMonitorSecondarydbRepository secondary;
    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }
    public BaseResultEntity save(SaveDatabaseMonitorParam param) {
        if (param.getDbType()==null||"".equals(param.getDbType().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"dbType");
        SysDatabaseMonitorConfig entity = new SysDatabaseMonitorConfig();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}