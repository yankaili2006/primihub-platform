package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveMiddlewareMonitorParam;
import com.primihub.biz.entity.sys.po.SysMiddlewareMonitorConfig;
import com.primihub.biz.repository.primarydb.sys.SysMiddlewareMonitorPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysMiddlewareMonitorSecondarydbRepository;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Service
public class SysMiddlewareMonitorService {
    @Autowired private SysMiddlewareMonitorPrimarydbRepository primary;
    @Autowired private SysMiddlewareMonitorSecondarydbRepository secondary;
    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }
    public BaseResultEntity save(SaveMiddlewareMonitorParam param) {
        if (param.getMwType()==null||"".equals(param.getMwType().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"mwType");
        SysMiddlewareMonitorConfig entity = new SysMiddlewareMonitorConfig();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }
    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}