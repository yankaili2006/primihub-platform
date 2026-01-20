package com.primihub.biz.service.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageParam;
import com.primihub.biz.entity.data.po.SharedDataset;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * 共享数据集管理Service
 * TODO: 后续实现数据库操作，当前使用模拟数据
 */
@Slf4j
@Service
public class SharedDatasetService {

    // 模拟数据存储
    private static final List<SharedDataset> mockDatasets = new ArrayList<>();
    private static Long idCounter = 6L;

    static {
        // 初始化测试数据
        SharedDataset ds1 = new SharedDataset();
        ds1.setId(1L);
        ds1.setDatasetCode("DS-2024-001");
        ds1.setDatasetName("用户行为数据集");
        ds1.setDataType("结构化数据");
        ds1.setDataFormat("CSV");
        ds1.setDataVolume(100000L);
        ds1.setShareStatus(1);
        ds1.setShareScope(2);
        ds1.setUserName("admin");
        ds1.setOrganName("机构A");
        ds1.setDataFields("user_id,action,timestamp,device");
        ds1.setDatasetDesc("用户行为分析数据集，包含用户操作记录");
        ds1.setUsageTerms("仅限于数据分析和模型训练使用");
        ds1.setIsDel(0);
        ds1.setCreateDate(new Date());
        ds1.setUpdateDate(new Date());
        mockDatasets.add(ds1);

        SharedDataset ds2 = new SharedDataset();
        ds2.setId(2L);
        ds2.setDatasetCode("DS-2024-002");
        ds2.setDatasetName("金融交易数据集");
        ds2.setDataType("结构化数据");
        ds2.setDataFormat("Parquet");
        ds2.setDataVolume(500000L);
        ds2.setShareStatus(1);
        ds2.setShareScope(1);
        ds2.setUserName("admin");
        ds2.setOrganName("机构A");
        ds2.setDataFields("transaction_id,amount,merchant,category,timestamp");
        ds2.setDatasetDesc("金融交易记录数据集");
        ds2.setUsageTerms("需签署数据使用协议");
        ds2.setIsDel(0);
        ds2.setCreateDate(new Date());
        ds2.setUpdateDate(new Date());
        mockDatasets.add(ds2);

        SharedDataset ds3 = new SharedDataset();
        ds3.setId(3L);
        ds3.setDatasetCode("DS-2024-003");
        ds3.setDatasetName("医疗健康数据集");
        ds3.setDataType("半结构化数据");
        ds3.setDataFormat("JSON");
        ds3.setDataVolume(50000L);
        ds3.setShareStatus(0);
        ds3.setShareScope(0);
        ds3.setUserName("admin");
        ds3.setOrganName("机构A");
        ds3.setDataFields("patient_id,diagnosis,treatment,outcome");
        ds3.setDatasetDesc("脱敏后的医疗健康数据");
        ds3.setUsageTerms("仅限医疗研究使用");
        ds3.setIsDel(0);
        ds3.setCreateDate(new Date());
        ds3.setUpdateDate(new Date());
        mockDatasets.add(ds3);

        SharedDataset ds4 = new SharedDataset();
        ds4.setId(4L);
        ds4.setDatasetCode("DS-2024-004");
        ds4.setDatasetName("电商商品数据集");
        ds4.setDataType("结构化数据");
        ds4.setDataFormat("CSV");
        ds4.setDataVolume(200000L);
        ds4.setShareStatus(3);
        ds4.setShareScope(2);
        ds4.setUserName("admin");
        ds4.setOrganName("机构A");
        ds4.setDataFields("product_id,name,category,price,sales");
        ds4.setDatasetDesc("电商平台商品信息数据集");
        ds4.setUsageTerms("可用于推荐系统训练");
        ds4.setIsDel(0);
        ds4.setCreateDate(new Date());
        ds4.setUpdateDate(new Date());
        mockDatasets.add(ds4);

        SharedDataset ds5 = new SharedDataset();
        ds5.setId(5L);
        ds5.setDatasetCode("DS-2024-005");
        ds5.setDatasetName("图像识别训练集");
        ds5.setDataType("非结构化数据");
        ds5.setDataFormat("其他");
        ds5.setDataVolume(10000L);
        ds5.setShareStatus(2);
        ds5.setShareScope(1);
        ds5.setUserName("admin");
        ds5.setOrganName("机构A");
        ds5.setDataFields("image_path,label,category");
        ds5.setDatasetDesc("图像分类训练数据集");
        ds5.setUsageTerms("仅限图像识别模型训练");
        ds5.setIsDel(0);
        ds5.setCreateDate(new Date());
        ds5.setUpdateDate(new Date());
        mockDatasets.add(ds5);
    }

    // ========== 共享数据集 CRUD ==========

    /**
     * 查询共享数据集分页列表
     */
    public BaseResultEntity findSharedDatasetPage(String keyword, String dataType,
                                                   Integer shareStatus, Long userId,
                                                   Long organId, Integer pageNum,
                                                   Integer pageSize) {
        try {
            // TODO: 实现数据库查询
            List<SharedDataset> filteredList = new ArrayList<>();
            for (SharedDataset ds : mockDatasets) {
                if (ds.getIsDel() != null && ds.getIsDel() == 1) {
                    continue;
                }
                boolean match = true;
                if (keyword != null && !keyword.isEmpty()) {
                    match = (ds.getDatasetCode() != null && ds.getDatasetCode().contains(keyword)) ||
                            (ds.getDatasetName() != null && ds.getDatasetName().contains(keyword));
                }
                if (match && dataType != null && !dataType.isEmpty()) {
                    match = dataType.equals(ds.getDataType());
                }
                if (match && shareStatus != null) {
                    match = shareStatus.equals(ds.getShareStatus());
                }
                if (match) {
                    filteredList.add(ds);
                }
            }

            int total = filteredList.size();
            PageParam pageParam = new PageParam(pageNum, pageSize);
            pageParam.initItemTotalCount((long) total);

            int fromIndex = pageParam.getPageIndex();
            int toIndex = Math.min(fromIndex + pageSize, total);
            List<SharedDataset> pageList = fromIndex < total ?
                    filteredList.subList(fromIndex, toIndex) : new ArrayList<>();

            Map<String, Object> result = new HashMap<>();
            result.put("list", pageList);
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
            // TODO: 实现数据库查询
            for (SharedDataset ds : mockDatasets) {
                if (ds.getId().equals(id) && (ds.getIsDel() == null || ds.getIsDel() == 0)) {
                    return BaseResultEntity.success(ds);
                }
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
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
            // 参数校验
            if (sharedDataset.getDatasetCode() == null || sharedDataset.getDatasetCode().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "数据集编码不能为空");
            }
            if (sharedDataset.getDatasetName() == null || sharedDataset.getDatasetName().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "数据集名称不能为空");
            }

            // TODO: 检查数据集编码是否已存在
            for (SharedDataset ds : mockDatasets) {
                if (ds.getDatasetCode().equals(sharedDataset.getDatasetCode()) &&
                        (ds.getIsDel() == null || ds.getIsDel() == 0)) {
                    return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "数据集编码已存在");
                }
            }

            // 设置默认值
            if (sharedDataset.getShareStatus() == null) {
                sharedDataset.setShareStatus(0); // 默认待审核
            }
            if (sharedDataset.getShareScope() == null) {
                sharedDataset.setShareScope(0); // 默认仅本机构
            }

            // TODO: 实现数据库插入
            sharedDataset.setId(idCounter++);
            sharedDataset.setIsDel(0);
            sharedDataset.setCreateDate(new Date());
            sharedDataset.setUpdateDate(new Date());
            mockDatasets.add(sharedDataset);

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

            // TODO: 实现数据库更新
            for (int i = 0; i < mockDatasets.size(); i++) {
                SharedDataset ds = mockDatasets.get(i);
                if (ds.getId().equals(sharedDataset.getId())) {
                    sharedDataset.setCreateDate(ds.getCreateDate());
                    sharedDataset.setUpdateDate(new Date());
                    sharedDataset.setIsDel(ds.getIsDel());
                    mockDatasets.set(i, sharedDataset);
                    return BaseResultEntity.success("更新成功");
                }
            }

            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
        } catch (Exception e) {
            log.error("更新共享数据集失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "更新失败");
        }
    }

    /**
     * 删除共享数据集
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteSharedDataset(Long id) {
        try {
            // TODO: 实现数据库软删除
            for (SharedDataset ds : mockDatasets) {
                if (ds.getId().equals(id)) {
                    ds.setIsDel(1);
                    ds.setUpdateDate(new Date());
                    return BaseResultEntity.success("删除成功");
                }
            }
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
        } catch (Exception e) {
            log.error("删除共享数据集失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "删除失败");
        }
    }

    /**
     * 批量删除共享数据集
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity batchDeleteSharedDataset(List<Long> ids) {
        try {
            if (ids == null || ids.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "ID列表不能为空");
            }

            // TODO: 实现数据库批量软删除
            int count = 0;
            for (SharedDataset ds : mockDatasets) {
                if (ids.contains(ds.getId())) {
                    ds.setIsDel(1);
                    ds.setUpdateDate(new Date());
                    count++;
                }
            }

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

            // TODO: 实现数据库更新
            for (SharedDataset ds : mockDatasets) {
                if (ds.getId().equals(id)) {
                    ds.setShareStatus(status);
                    ds.setUpdateDate(new Date());
                    return BaseResultEntity.success("状态更新成功");
                }
            }

            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "共享数据集不存在");
        } catch (Exception e) {
            log.error("更新共享数据集状态失败，id={}", id, e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "状态更新失败");
        }
    }

    /**
     * 获取可共享的资源列表
     */
    public BaseResultEntity getShareableResources(Long organId) {
        try {
            // TODO: 从资源表中查询可共享的资源
            List<Map<String, Object>> resources = new ArrayList<>();

            Map<String, Object> res1 = new HashMap<>();
            res1.put("resourceId", 1L);
            res1.put("resourceName", "用户数据资源");
            resources.add(res1);

            Map<String, Object> res2 = new HashMap<>();
            res2.put("resourceId", 2L);
            res2.put("resourceName", "交易数据资源");
            resources.add(res2);

            Map<String, Object> res3 = new HashMap<>();
            res3.put("resourceId", 3L);
            res3.put("resourceName", "商品数据资源");
            resources.add(res3);

            return BaseResultEntity.success(resources);
        } catch (Exception e) {
            log.error("获取可共享资源列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, "查询失败");
        }
    }
}
