package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveComputeLogTypeParam;
import com.primihub.biz.service.sys.SysComputeLogTypeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("computeLogType")
@RestController
public class ComputeLogTypeController {
    @Autowired private SysComputeLogTypeService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveComputeLogTypeParam param) {
        if (param.getTypeName()==null||"".equals(param.getTypeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"typeName");
        if (param.getTypeCode()==null||"".equals(param.getTypeCode().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"typeCode");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}