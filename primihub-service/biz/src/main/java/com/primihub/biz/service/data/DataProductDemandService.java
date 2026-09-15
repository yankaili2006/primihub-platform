package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.DataProductDemand;
import com.primihub.biz.repository.primarydb.data.DataProductDemandPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 数据产品需求Service
 */
@Slf4j
@Service
public class DataProductDemandService {

    @Autowired
    private DataProductDemandPrimarydbRepository demandRepository;

    /**
     * 查询数据产品需求分页列表
     */
    public BaseResultEntity findDemandPage(String demandName, String demandType,
                                          String status, Long organId,
                                          Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("demandName", demandName);
            params.put("demandType", demandType);
            params.put("status", status);
            params.put("organId", organId);

            int total = demandRepository.selectDataProductDemandCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("pageNo", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<DataProductDemand> list = demandRepository.selectDataProductDemandList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("total", total);
            result.put("pageNum", pageNum);
            result.put("pageSize", pageSize);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询数据产品需求列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 根据ID查询数据产品需求
     */
    public BaseResultEntity findDemandById(Long id) {
        try {
            DataProductDemand demand = demandRepository.selectDataProductDemandById(id);
            if (demand == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "需求不存在");
            }
            return BaseResultEntity.success(demand);
        } catch (Exception e) {
            log.error("查询数据产品需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 新增数据产品需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveDemand(DataProductDemand demand) {
        try {
            if (demand.getStatus() == null) {
                demand.setStatus("待处理");
            }
            if (demand.getPriority() == null) {
                demand.setPriority("中");
            }
            int result = demandRepository.insertDataProductDemand(demand);
            if (result > 0) {
                return BaseResultEntity.success(demand);
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "新增失败");
        } catch (Exception e) {
            log.error("新增数据产品需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 更新数据产品需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateDemand(DataProductDemand demand) {
        try {
            if (demand.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            DataProductDemand existing = demandRepository.selectDataProductDemandById(demand.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "需求不存在");
            }
            int result = demandRepository.updateDataProductDemand(demand);
            if (result > 0) {
                return BaseResultEntity.success(demand);
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "更新失败");
        } catch (Exception e) {
            log.error("更新数据产品需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 删除数据产品需求
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteDemand(Long id) {
        try {
            DataProductDemand existing = demandRepository.selectDataProductDemandById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "需求不存在");
            }
            int result = demandRepository.deleteDataProductDemand(id);
            if (result > 0) {
                return BaseResultEntity.success();
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        } catch (Exception e) {
            log.error("删除数据产品需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 统计数据
     */
    public BaseResultEntity getStatistics(Long organId) {
        try {
            Map<String, Object> params = new HashMap<>();
            if (organId != null) {
                params.put("organId", organId);
            }

            int total = demandRepository.selectDataProductDemandCount(params);

            params.put("status", "待处理");
            int pending = demandRepository.selectDataProductDemandCount(params);

            params.put("status", "进行中");
            int inProgress = demandRepository.selectDataProductDemandCount(params);

            params.put("status", "已完成");
            int completed = demandRepository.selectDataProductDemandCount(params);

            Map<String, Object> stats = new HashMap<>();
            stats.put("total", total);
            stats.put("pending", pending);
            stats.put("inProgress", inProgress);
            stats.put("completed", completed);

            return BaseResultEntity.success(stats);
        } catch (Exception e) {
            log.error("统计数据产品需求失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }
}
