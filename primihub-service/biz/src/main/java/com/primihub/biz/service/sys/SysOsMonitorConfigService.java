package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveMonitorConfigParam;
import com.primihub.biz.entity.sys.po.SysOsMonitorConfig;
import com.primihub.biz.repository.primarydb.sys.SysOsMonitorConfigPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysOsMonitorConfigSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
@Slf4j
@Service
public class SysOsMonitorConfigService {
    @Autowired private SysOsMonitorConfigPrimarydbRepository primary;
    @Autowired private SysOsMonitorConfigSecondarydbRepository secondary;
    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }
    public BaseResultEntity save(SaveMonitorConfigParam param) {
        if (param.getConfigKey()==null||"".equals(param.getConfigKey().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"configKey");
        if (param.getConfigName()==null||"".equals(param.getConfigName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"configName");
        SysOsMonitorConfig entity = new SysOsMonitorConfig();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}