package com.primihub.biz.service.data;

import com.primihub.biz.config.base.OrganConfiguration;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.data.po.DataTrustedSpace;
import com.primihub.biz.entity.data.req.DataResourceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceResourceReq;
import com.primihub.biz.entity.data.vo.DataTrustedSpaceVo;
import com.primihub.biz.repository.primarydb.data.DataTrustedSpacePrRepository;
import com.primihub.biz.repository.secondarydb.data.DataTrustedSpaceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * 可信空间：独立实体 + CRUD + 资源归属。
 * <p>
 * 约定：data_resource.trusted_space = data_trusted_space.space_id；NULL 表示缺省空间（is_default=1）。
 * 缺省空间不可删除、不可停用、不可改编码。删除非缺省空间时其资源置回缺省（NULL）。
 * 空间为机构本地实体，不随 fusion 同步给协作方。
 */
@Slf4j
@Service
public class DataTrustedSpaceService {

    public static final Pattern CODE_PATTERN = Pattern.compile("^[A-Za-z0-9_-]{1,64}$");
    public static final int NAME_MAX_LEN = 128;
    public static final int DESC_MAX_LEN = 512;

    @Autowired
    private DataTrustedSpaceRepository trustedSpaceRepository;
    @Autowired
    private DataTrustedSpacePrRepository trustedSpacePrRepository;
    @Autowired
    private OrganConfiguration organConfiguration;
    @Autowired
    private DataResourceService dataResourceService;

    public BaseResultEntity page(TrustedSpaceReq req) {
        Map<String, Object> paramMap = new HashMap<>();
        paramMap.put("spaceName", req.getSpaceName());
        paramMap.put("spaceCode", req.getSpaceCode());
        paramMap.put("status", req.getStatus());
        paramMap.put("offset", req.getOffset());
        paramMap.put("pageSize", req.getPageSize());
        List<DataTrustedSpace> list = trustedSpaceRepository.selectTrustedSpacePage(paramMap);
        if (list == null || list.isEmpty()) {
            return BaseResultEntity.success(new PageDataEntity<>(0, req.getPageSize(), req.getPageNo(), new ArrayList<>()));
        }
        Integer count = trustedSpaceRepository.selectTrustedSpaceCount(paramMap);
        List<DataTrustedSpaceVo> voList = withResourceCount(list);
        return BaseResultEntity.success(new PageDataEntity<>(count == null ? voList.size() : count, req.getPageSize(), req.getPageNo(), voList));
    }

    public BaseResultEntity listAll() {
        List<DataTrustedSpace> list = trustedSpaceRepository.selectAllEnabled();
        return BaseResultEntity.success(withResourceCount(list == null ? new ArrayList<>() : list));
    }

    public BaseResultEntity detail(Long spaceId) {
        DataTrustedSpace po = trustedSpaceRepository.selectTrustedSpaceById(spaceId);
        if (po == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        DataTrustedSpaceVo vo = DataTrustedSpaceVo.of(po);
        Integer cnt = trustedSpaceRepository.countResourcesBySpace(po.getSpaceId(), po.getIsDefault());
        vo.setResourceCount(cnt == null ? 0 : cnt);
        return BaseResultEntity.success(vo);
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity save(TrustedSpaceReq req, Long userId) {
        String name = trim(req.getSpaceName());
        if (name.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceName");
        }
        if (name.length() > NAME_MAX_LEN) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceName 过长");
        }
        String desc = trim(req.getSpaceDesc());
        if (desc.length() > DESC_MAX_LEN) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceDesc 过长");
        }
        if (req.getStatus() != null && req.getStatus() != 0 && req.getStatus() != 1) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "status");
        }
        String code = trim(req.getSpaceCode());
        if (code.isEmpty()) {
            code = generateCode();
        } else if (!CODE_PATTERN.matcher(code).matches()) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceCode 仅允许字母数字 _ -，长度 1-64");
        }
        if (trustedSpaceRepository.selectTrustedSpaceByName(name, null) != null) {
            return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "空间名称已存在");
        }
        if (trustedSpaceRepository.selectTrustedSpaceByCode(code, null) != null) {
            return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "空间编码已存在");
        }
        DataTrustedSpace po = new DataTrustedSpace();
        po.setSpaceCode(code);
        po.setSpaceName(name);
        po.setSpaceDesc(desc.isEmpty() ? null : desc);
        po.setOrganId(organConfiguration.getSysLocalOrganId());
        po.setOrganName(organConfiguration.getSysLocalOrganName());
        po.setIsDefault(0);
        po.setStatus(req.getStatus() == null ? 1 : req.getStatus());
        po.setSortIndex(req.getSortIndex() == null ? 100 : req.getSortIndex());
        po.setUserId(userId);
        try {
            trustedSpacePrRepository.insertTrustedSpace(po);
        } catch (Exception e) {
            log.error("insert trusted space fail, name={}, code={}", name, code, e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL, "保存可信空间失败");
        }
        return BaseResultEntity.success(DataTrustedSpaceVo.of(po));
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity update(TrustedSpaceReq req, Long userId) {
        if (req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        DataTrustedSpace exist = trustedSpaceRepository.selectTrustedSpaceById(req.getSpaceId());
        if (exist == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        boolean isDefault = exist.getIsDefault() != null && exist.getIsDefault() == 1;
        DataTrustedSpace upd = new DataTrustedSpace();
        upd.setSpaceId(exist.getSpaceId());
        boolean changed = false;
        if (req.getSpaceName() != null) {
            String name = trim(req.getSpaceName());
            if (name.isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceName 不能为空");
            }
            if (name.length() > NAME_MAX_LEN) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceName 过长");
            }
            if (!name.equals(exist.getSpaceName())) {
                if (trustedSpaceRepository.selectTrustedSpaceByName(name, exist.getSpaceId()) != null) {
                    return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "空间名称已存在");
                }
                upd.setSpaceName(name);
                changed = true;
            }
        }
        if (req.getSpaceCode() != null) {
            String code = trim(req.getSpaceCode());
            if (!code.isEmpty() && !code.equals(exist.getSpaceCode())) {
                if (isDefault) {
                    return BaseResultEntity.failure(BaseResultEnum.CAN_NOT_ALTER, "缺省空间编码不可修改");
                }
                if (!CODE_PATTERN.matcher(code).matches()) {
                    return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceCode 仅允许字母数字 _ -，长度 1-64");
                }
                if (trustedSpaceRepository.selectTrustedSpaceByCode(code, exist.getSpaceId()) != null) {
                    return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE, "空间编码已存在");
                }
                upd.setSpaceCode(code);
                changed = true;
            }
        }
        if (req.getSpaceDesc() != null) {
            String desc = trim(req.getSpaceDesc());
            if (desc.length() > DESC_MAX_LEN) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "spaceDesc 过长");
            }
            upd.setSpaceDesc(desc);
            changed = true;
        }
        if (req.getStatus() != null) {
            if (req.getStatus() != 0 && req.getStatus() != 1) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "status");
            }
            if (isDefault && req.getStatus() == 0) {
                return BaseResultEntity.failure(BaseResultEnum.CAN_NOT_ALTER, "缺省空间不可停用");
            }
            upd.setStatus(req.getStatus());
            changed = true;
        }
        if (req.getSortIndex() != null) {
            upd.setSortIndex(req.getSortIndex());
            changed = true;
        }
        if (!changed) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "至少需要一个修改的字段");
        }
        try {
            trustedSpacePrRepository.updateTrustedSpace(upd);
        } catch (Exception e) {
            log.error("update trusted space fail, spaceId={}", exist.getSpaceId(), e);
            return BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL, "编辑可信空间失败");
        }
        return detail(exist.getSpaceId());
    }

    /**
     * 软删空间；其资源置回缺省（trusted_space = NULL）。返回 movedResources = 被置回的资源数。
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity delete(Long spaceId) {
        DataTrustedSpace exist = trustedSpaceRepository.selectTrustedSpaceById(spaceId);
        if (exist == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        if (exist.getIsDefault() != null && exist.getIsDefault() == 1) {
            return BaseResultEntity.failure(BaseResultEnum.CAN_NOT_DELETE, "缺省空间不可删除");
        }
        try {
            int moved = trustedSpacePrRepository.clearResourceTrustedSpace(spaceId, null);
            trustedSpacePrRepository.deleteTrustedSpace(spaceId);
            Map<String, Object> result = new HashMap<>();
            result.put("spaceId", spaceId);
            result.put("movedResources", moved);
            return BaseResultEntity.success(result);
        } catch (Exception e) {
            log.error("delete trusted space fail, spaceId={}", spaceId, e);
            throw e;
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity assignResources(TrustedSpaceResourceReq req) {
        List<Long> ids = distinctIds(req.getResourceIds());
        if (req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        if (ids.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resourceIds");
        }
        DataTrustedSpace space = trustedSpaceRepository.selectTrustedSpaceById(req.getSpaceId());
        if (space == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        if (space.getStatus() != null && space.getStatus() != 1) {
            return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "空间已停用，不能划入资源");
        }
        int affected = trustedSpacePrRepository.updateResourceTrustedSpace(space.getSpaceId(), ids);
        Map<String, Object> result = new HashMap<>();
        result.put("spaceId", space.getSpaceId());
        result.put("affected", affected);
        return BaseResultEntity.success(result);
    }

    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity removeResources(TrustedSpaceResourceReq req) {
        List<Long> ids = distinctIds(req.getResourceIds());
        if (req.getSpaceId() == null || req.getSpaceId() == 0L) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "spaceId");
        }
        if (ids.isEmpty()) {
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "resourceIds");
        }
        DataTrustedSpace space = trustedSpaceRepository.selectTrustedSpaceById(req.getSpaceId());
        if (space == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        if (space.getIsDefault() != null && space.getIsDefault() == 1) {
            return BaseResultEntity.failure(BaseResultEnum.CAN_NOT_ALTER, "缺省空间的资源无需移出，请直接划入目标空间");
        }
        int affected = trustedSpacePrRepository.clearResourceTrustedSpace(space.getSpaceId(), ids);
        Map<String, Object> result = new HashMap<>();
        result.put("spaceId", space.getSpaceId());
        result.put("affected", affected);
        return BaseResultEntity.success(result);
    }

    /**
     * 空间内资源分页：复用资源列表查询（同一套 DataResourceVo：标签/用户名/空间名），缺省空间含 NULL 资源。
     */
    public BaseResultEntity resourcePage(Long spaceId, DataResourceReq req, Long userId) {
        DataTrustedSpace space = trustedSpaceRepository.selectTrustedSpaceById(spaceId);
        if (space == null) {
            return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL, "可信空间不存在");
        }
        if (req == null) {
            req = new DataResourceReq();
        }
        req.setTrustedSpace(space.getSpaceId());
        req.setTrustedSpaceIncludeDefault(space.getIsDefault() != null && space.getIsDefault() == 1);
        req.setTrustedSpaceName(null);
        return dataResourceService.getDataResourceList(req, userId);
    }

    // ---------- helpers ----------

    private List<DataTrustedSpaceVo> withResourceCount(List<DataTrustedSpace> list) {
        Map<Long, Integer> counts = new HashMap<>();
        int nullCount = 0;
        List<Map<String, Object>> rows = trustedSpaceRepository.selectResourceCountGroupBySpace();
        if (rows != null) {
            for (Map<String, Object> row : rows) {
                Object sid = row.get("spaceId");
                Object cnt = row.get("cnt");
                int c = cnt == null ? 0 : ((Number) cnt).intValue();
                if (sid == null) {
                    nullCount += c;
                } else {
                    counts.merge(((Number) sid).longValue(), c, Integer::sum);
                }
            }
        }
        final int unassigned = nullCount;
        return list.stream().map(po -> {
            DataTrustedSpaceVo vo = DataTrustedSpaceVo.of(po);
            int c = counts.getOrDefault(po.getSpaceId(), 0);
            if (vo.getIsDefault() == 1) {
                c += unassigned;
            }
            vo.setResourceCount(c);
            return vo;
        }).collect(Collectors.toList());
    }

    static List<Long> distinctIds(List<Long> ids) {
        if (ids == null) {
            return new ArrayList<>();
        }
        return ids.stream().filter(Objects::nonNull).filter(id -> id > 0).distinct().collect(Collectors.toList());
    }

    static String generateCode() {
        String ts = new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
        return "ts_" + ts + "_" + Integer.toHexString(ThreadLocalRandom.current().nextInt(0x1000, 0xFFFF));
    }

    private static String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
