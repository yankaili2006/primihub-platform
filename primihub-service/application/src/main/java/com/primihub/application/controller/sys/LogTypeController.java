package com.primihub.application.controller.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveLogTypeParam;
import com.primihub.biz.service.sys.SysLogTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequestMapping("logType")
@RestController
public class LogTypeController {
    @Autowired private SysLogTypeService sysLogTypeService;

    @RequestMapping("getLogTypeList")
    public BaseResultEntity getLogTypeList() {
        return sysLogTypeService.getLogTypeList();
    }

    @RequestMapping("saveLogType")
    public BaseResultEntity saveLogType(SaveLogTypeParam param) {
        if (param.getTypeName() == null || "".equals(param.getTypeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "typeName");
        if (param.getTypeCode() == null || "".equals(param.getTypeCode().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "typeCode");
        return sysLogTypeService.saveLogType(param);
    }

    @RequestMapping("deleteLogType")
    public BaseResultEntity deleteLogType(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        return sysLogTypeService.deleteLogType(id);
    }
}