package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveMiddlewareMonitorParam;
import com.primihub.biz.service.sys.SysMiddlewareMonitorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("middlewareMonitor")
@RestController
public class MiddlewareMonitorController {
    @Autowired private SysMiddlewareMonitorService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveMiddlewareMonitorParam param) {
        if (param.getMwType()==null||"".equals(param.getMwType().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"mwType");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}