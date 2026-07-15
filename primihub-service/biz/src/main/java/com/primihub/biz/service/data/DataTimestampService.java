package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.param.ApplyTimestampParam;
import com.primihub.biz.entity.data.param.FindTimestampPageParam;
import com.primihub.biz.entity.data.po.DataTimestamp;
import com.primihub.biz.repository.primarydb.data.DataTimestampPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.data.DataTimestampSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class DataTimestampService {

    @Autowired
    private DataTimestampPrimarydbRepository dataTimestampPrimarydbRepository;
    @Autowired
    private DataTimestampSecondarydbRepository dataTimestampSecondarydbRepository;

    /**
     * 分页查询时间戳列表
     */
    public BaseResultEntity findTimestampPage(FindTimestampPageParam param) {
        if (param.getPageNum() == null || param.getPageNum() < 1) param.setPageNum(1);
        if (param.getPageSize() == null || param.getPageSize() < 1) param.setPageSize(10);
        List<DataTimestamp> list = dataTimestampSecondarydbRepository.selectTimestampPage(param);
        Integer total = dataTimestampSecondarydbRepository.selectTimestampCount(param);
        int pageCount = (int) Math.ceil((double) total / param.getPageSize());
        Map<String, Object> result = new HashMap<>();
        result.put("list", list);
        result.put("total", total);
        result.put("pageNum", param.getPageNum());
        result.put("pageSize", param.getPageSize());
        result.put("pageCount", pageCount);
        return BaseResultEntity.success(result);
    }

    /**
     * 申请时间戳
     */
    public BaseResultEntity applyTimestamp(ApplyTimestampParam param, Long userId, String userName) {
        if (param.getTitle() == null || "".equals(param.getTitle().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "title");
        }
        if (param.getFileHash() == null || "".equals(param.getFileHash().trim())) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "fileHash");
        }
        DataTimestamp ts = new DataTimestamp();
        BeanUtils.copyProperties(param, ts);
        ts.setApplyId("TS" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        ts.setApplyStatus(0);
        ts.setApplyUserId(userId > 0 ? userId : null);
        ts.setApplyUserName(userName);
        dataTimestampPrimarydbRepository.insertTimestamp(ts);
        return BaseResultEntity.success(ts);
    }

    /**
     * 提交时间戳申请（提交后状态变为1-已提交，模拟提交到授时中心）
     */
    public BaseResultEntity submitTimestamp(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        DataTimestamp ts = dataTimestampSecondarydbRepository.selectTimestampById(id);
        if (ts == null) return BaseResultEntity.failure(BaseResultEnum.DATA_NOT_EXIST);
        // 模拟提交到授时中心，生成时间戳值和证书编号
        String tsValue = String.valueOf(System.currentTimeMillis() / 1000);
        String certNo = "CERT" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        dataTimestampPrimarydbRepository.updateTimestampStatus(id, 2, tsValue, certNo);
        return BaseResultEntity.success();
    }

    /**
     * 删除时间戳
     */
    public BaseResultEntity deleteTimestamp(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        dataTimestampPrimarydbRepository.deleteTimestamp(id);
        return BaseResultEntity.success();
    }

    /**
     * 获取时间戳详情
     */
    public BaseResultEntity getTimestampDetail(Long id) {
        if (id == null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "id");
        DataTimestamp ts = dataTimestampSecondarydbRepository.selectTimestampById(id);
        if (ts == null) return BaseResultEntity.failure(BaseResultEnum.DATA_NOT_EXIST);
        return BaseResultEntity.success(ts);
    }
}