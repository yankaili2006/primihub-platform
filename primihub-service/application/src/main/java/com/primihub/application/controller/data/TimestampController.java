package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.param.ApplyTimestampParam;
import com.primihub.biz.entity.data.param.FindTimestampPageParam;
import com.primihub.biz.service.data.DataTimestampService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 时间戳管理 Controller
 */
@RequestMapping("timestamp")
@RestController
public class TimestampController {

    @Autowired
    private DataTimestampService dataTimestampService;

    @RequestMapping("findTimestampPage")
    public BaseResultEntity findTimestampPage(FindTimestampPageParam param) {
        return dataTimestampService.findTimestampPage(param);
    }

    @RequestMapping("applyTimestamp")
    public BaseResultEntity applyTimestamp(ApplyTimestampParam param,
                                            @RequestHeader(value = "userId", defaultValue = "-1") Long userId,
                                            @RequestHeader(value = "userName", defaultValue = "") String userName) {
        if (param.getTitle() == null || "".equals(param.getTitle().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "title");
        }
        param.setFileHash(param.getFileHash() != null ? param.getFileHash().trim() : null);
        return dataTimestampService.applyTimestamp(param, userId, userName);
    }

    @RequestMapping("submitTimestamp")
    public BaseResultEntity submitTimestamp(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        return dataTimestampService.submitTimestamp(id);
    }

    @RequestMapping("deleteTimestamp")
    public BaseResultEntity deleteTimestamp(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        return dataTimestampService.deleteTimestamp(id);
    }

    @RequestMapping("getTimestampDetail")
    public BaseResultEntity getTimestampDetail(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        return dataTimestampService.getTimestampDetail(id);
    }
}