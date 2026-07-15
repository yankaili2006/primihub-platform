package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.TriggerSyncParam;
import com.primihub.biz.entity.sys.po.SysDataExchangeLog;
import com.primihub.biz.repository.primarydb.sys.SysDataExchangeLogPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysDataExchangeLogSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Slf4j
@Service
public class SysDataExchangeLogService {
    @Autowired private SysDataExchangeLogPrimarydbRepository primary;
    @Autowired private SysDataExchangeLogSecondarydbRepository secondary;

    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }

    public BaseResultEntity triggerSync(TriggerSyncParam param) {
        if (param.getExchangeName()==null||"".equals(param.getExchangeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"exchangeName");
        SysDataExchangeLog entity = new SysDataExchangeLog();
        BeanUtils.copyProperties(param, entity);
        entity.setExchangeType(param.getExchangeType()!=null?param.getExchangeType():"RESOURCE");
        primary.insert(entity);
        // 模拟同步过程
        try {
            Thread.sleep(500);
            primary.updateSyncStatus(entity.getId(), 2, "同步完成");
        } catch (Exception e) {
            primary.updateSyncStatus(entity.getId(), 3, "同步失败: "+e.getMessage());
        }
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}