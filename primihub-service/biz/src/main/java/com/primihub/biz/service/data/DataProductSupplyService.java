package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.DataProductSupply;
import com.primihub.biz.repository.primarydb.data.DataProductSupplyPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 数据产品供给Service
 */
@Slf4j
@Service
public class DataProductSupplyService {

    @Autowired
    private DataProductSupplyPrimarydbRepository supplyRepository;

    /**
     * 查询数据产品供给分页列表
     */
    public BaseResultEntity findSupplyPage(String productName, String serviceCategory,
                                          String status, Long organId, Long nodeId,
                                          Integer pageNum, Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("productName", productName);
            params.put("serviceCategory", serviceCategory);
            params.put("status", status);
            params.put("organId", organId);
            params.put("nodeId", nodeId);

            int total = supplyRepository.selectDataProductSupplyCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("pageNo", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<DataProductSupply> list = supplyRepository.selectDataProductSupplyList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("total", total);
            result.put("pageNum", pageNum);
            result.put("pageSize", pageSize);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询数据产品供给列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 根据ID查询数据产品供给
     */
    public BaseResultEntity findSupplyById(Long id) {
        try {
            DataProductSupply supply = supplyRepository.selectDataProductSupplyById(id);
            if (supply == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "产品不存在");
            }
            return BaseResultEntity.success(supply);
        } catch (Exception e) {
            log.error("查询数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 根据机构ID查询
     */
    public BaseResultEntity findSupplyByOrganId(Long organId) {
        try {
            List<DataProductSupply> list = supplyRepository.selectDataProductSupplyByOrganId(organId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("按机构查询数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 根据节点ID查询
     */
    public BaseResultEntity findSupplyByNodeId(Long nodeId) {
        try {
            List<DataProductSupply> list = supplyRepository.selectDataProductSupplyByNodeId(nodeId);
            return BaseResultEntity.success(list);
        } catch (Exception e) {
            log.error("按节点查询数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 新增数据产品供给
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveSupply(DataProductSupply supply) {
        try {
            if (supply.getStatus() == null) {
                supply.setStatus("上架");
            }
            if (supply.getQualityLevel() == null) {
                supply.setQualityLevel("标准");
            }
            int result = supplyRepository.insertDataProductSupply(supply);
            if (result > 0) {
                return BaseResultEntity.success(supply);
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "新增失败");
        } catch (Exception e) {
            log.error("新增数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 更新数据产品供给
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateSupply(DataProductSupply supply) {
        try {
            if (supply.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            DataProductSupply existing = supplyRepository.selectDataProductSupplyById(supply.getId());
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "产品不存在");
            }
            int result = supplyRepository.updateDataProductSupply(supply);
            if (result > 0) {
                return BaseResultEntity.success(supply);
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "更新失败");
        } catch (Exception e) {
            log.error("更新数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 删除数据产品供给
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteSupply(Long id) {
        try {
            DataProductSupply existing = supplyRepository.selectDataProductSupplyById(id);
            if (existing == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "产品不存在");
            }
            int result = supplyRepository.deleteDataProductSupply(id);
            if (result > 0) {
                return BaseResultEntity.success();
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL, "删除失败");
        } catch (Exception e) {
            log.error("删除数据产品供给失败", e);
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

            int total = supplyRepository.selectDataProductSupplyCount(params);

            params.put("status", "上架");
            int online = supplyRepository.selectDataProductSupplyCount(params);

            params.put("status", "下架");
            int offline = supplyRepository.selectDataProductSupplyCount(params);

            params.put("status", "维护中");
            int maintenance = supplyRepository.selectDataProductSupplyCount(params);

            Map<String, Object> stats = new HashMap<>();
            stats.put("total", total);
            stats.put("online", online);
            stats.put("offline", offline);
            stats.put("maintenance", maintenance);

            return BaseResultEntity.success(stats);
        } catch (Exception e) {
            log.error("统计数据产品供给失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }
}
