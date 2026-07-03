package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.SharedDataset;
import com.primihub.biz.repository.primarydb.data.SharedDatasetPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 共享数据集管理Service —— 真实数据库持久化。
 * （原实现是 static mockDatasets 内存表 + 5 条硬编码示例：增删改一律"请求成功"却不落库、
 *  重启即失、3 个机构各自一份内存，属"假请求成功"缺陷。现改为 shared_dataset 表真持久化。）
 */
@Slf4j
@Service
public class SharedDatasetService {

    @Autowired
    private SharedDatasetPrimarydbRepository sharedDatasetRepository;

    // ========== 共享数据集 CRUD ==========

    /**
     * 查询共享数据集分页列表
     */
    public BaseResultEntity findSharedDatasetPage(String keyword, String dataType,
                                                   Integer shareStatus, Long userId,
                                                   Long organId, Integer pageNum,
                                                   Integer pageSize) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("keyword", keyword);
            params.put("dataType", dataType);
            params.put("shareStatus", shareStatus);
            params.put("userId", userId);
            params.put("organId", organId);

            int total = sharedDatasetRepository.selectSharedDatasetCount(params);

            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);
            params.put("offset", pageParam.getPageIndex());
            params.put("pageSize", pageParam.getPageSize());

            List<SharedDataset> list = sharedDatasetRepository.selectSharedDatasetList(params);

            Map<String, Object> result = new HashMap<>();
            result.put("list", list);
            result.put("pageParam", pageParam);

            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("查询共享数据集列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 根据ID查询共享数据集
     */
    public BaseResultEntity getSharedDatasetById(Long id) {
        try {
            SharedDataset ds = sharedDatasetRepository.selectSharedDatasetById(id);
            if (ds == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
            }
            return BaseResultEntity.success(ds);
        } catch (Exception e) {
            log.error("查询共享数据集失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }

    /**
     * 添加共享数据集
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity addSharedDataset(SharedDataset sharedDataset) {
        try {
            if (sharedDataset.getDatasetCode() == null || sharedDataset.getDatasetCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "数据集编码不能为空");
            }
            if (sharedDataset.getDatasetName() == null || sharedDataset.getDatasetName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "数据集名称不能为空");
            }

            // 编码唯一性校验（DB）
            SharedDataset exist = sharedDatasetRepository.selectSharedDatasetByCode(sharedDataset.getDatasetCode());
            if (exist != null) {
                return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "数据集编码已存在");
            }

            if (sharedDataset.getShareStatus() == null) {
                sharedDataset.setShareStatus(0); // 默认待审核
            }
            if (sharedDataset.getShareScope() == null) {
                sharedDataset.setShareScope(0); // 默认仅本机构
            }
            sharedDataset.setIsDel(0);

            int rows = sharedDatasetRepository.insertSharedDataset(sharedDataset);
            if (rows <= 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
            }
            return BaseResultEntity.success(sharedDataset);
        } catch (Exception e) {
            log.error("添加共享数据集失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "添加失败");
        }
    }

    /**
     * 更新共享数据集
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateSharedDataset(SharedDataset sharedDataset) {
        try {
            if (sharedDataset.getId() == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            SharedDataset exist = sharedDatasetRepository.selectSharedDatasetById(sharedDataset.getId());
            if (exist == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
            }
            int rows = sharedDatasetRepository.updateSharedDataset(sharedDataset);
            if (rows <= 0) {
                return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
            }
            return BaseResultEntity.success("更新成功");
        } catch (Exception e) {
            log.error("更新共享数据集失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除共享数据集（软删除）
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteSharedDataset(Long id) {
        try {
            int rows = sharedDatasetRepository.deleteSharedDataset(id);
            if (rows <= 0) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
            }
            return BaseResultEntity.success("删除成功");
        } catch (Exception e) {
            log.error("删除共享数据集失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 批量删除共享数据集（软删除）
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteSharedDataset(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }
            int count = sharedDatasetRepository.batchDeleteSharedDataset(ids);
            return BaseResultEntity.success("成功删除" + count + "条记录");
        } catch (Exception e) {
            log.error("批量删除共享数据集失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "批量删除失败");
        }
    }

    /**
     * 更新共享数据集状态
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity updateSharedDatasetStatus(Long id, Integer status) {
        try {
            if (id == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID不能为空");
            }
            if (status == null || status < 0 || status > 3) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "状态值无效");
            }
            int rows = sharedDatasetRepository.updateSharedDatasetStatus(id, status);
            if (rows <= 0) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
            }
            return BaseResultEntity.success("状态更新成功");
        } catch (Exception e) {
            log.error("更新共享数据集状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "状态更新失败");
        }
    }

    /**
     * 获取可共享的资源列表（查真实 data_resource 表）
     */
    public BaseResultEntity getShareableResources(Long organId) {
        try {
            List<Map<String, Object>> resources = sharedDatasetRepository.selectShareableResources(organId);
            if (resources == null) {
                resources = new ArrayList<>();
            }
            return BaseResultEntity.success(resources);
        } catch (Exception e) {
            log.error("获取可共享资源列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }
}
