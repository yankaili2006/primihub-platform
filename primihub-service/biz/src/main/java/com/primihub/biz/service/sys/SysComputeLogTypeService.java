package com.primihub.biz.service.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveComputeLogTypeParam;
import com.primihub.biz.entity.sys.po.SysComputeLogType;
import com.primihub.biz.repository.primarydb.sys.SysComputeLogTypePrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysComputeLogTypeSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
@Slf4j
@Service
public class SysComputeLogTypeService {
    @Autowired private SysComputeLogTypePrimarydbRepository primary;
    @Autowired private SysComputeLogTypeSecondarydbRepository secondary;

    public BaseResultEntity getList() { return BaseResultEntity.success(secondary.selectList()); }

    public BaseResultEntity save(SaveComputeLogTypeParam param) {
        if (param.getTypeName()==null||"".equals(param.getTypeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"typeName");
        if (param.getTypeCode()==null||"".equals(param.getTypeCode().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"typeCode");
        SysComputeLogType exist = secondary.selectByCode(param.getTypeCode().trim());
        if (exist!=null && (param.getId()==null||!param.getId().equals(exist.getId())))
            return BaseResultEntity.failure(BaseResultEnum.FAILURE,"类型编码已存在");
        SysComputeLogType entity = new SysComputeLogType();
        BeanUtils.copyProperties(param, entity);
        if (param.getId()==null) primary.insert(entity); else primary.update(entity);
        return BaseResultEntity.success();
    }

    public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        primary.delete(id); return BaseResultEntity.success();
    }
}