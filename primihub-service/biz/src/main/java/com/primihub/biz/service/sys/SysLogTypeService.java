package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveLogTypeParam;
import com.primihub.biz.entity.sys.po.SysLogType;
import com.primihub.biz.repository.primarydb.sys.SysLogTypePrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysLogTypeSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Slf4j
@Service
public class SysLogTypeService {
    @Autowired private SysLogTypePrimarydbRepository primary;
    @Autowired private SysLogTypeSecondarydbRepository secondary;

    public BaseResultEntity getLogTypeList() {
        return BaseResultEntity.success(secondary.selectLogTypeList());
    }

    public BaseResultEntity saveLogType(SaveLogTypeParam param) {
        if (param.getTypeName() == null || "".equals(param.getTypeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "typeName");
        if (param.getTypeCode() == null || "".equals(param.getTypeCode().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "typeCode");
        SysLogType exist = secondary.selectLogTypeByCode(param.getTypeCode().trim());
        if (exist != null && (param.getId() == null || !param.getId().equals(exist.getId())))
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "类型编码已存在");
        SysLogType entity = new SysLogType();
        BeanUtils.copyProperties(param, entity);
        if (param.getId() == null) {
            primary.insertLogType(entity);
        } else {
            primary.updateLogType(entity);
        }
        return BaseResultEntity.success();
    }

    public BaseResultEntity deleteLogType(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        primary.deleteLogType(id);
        return BaseResultEntity.success();
    }
}