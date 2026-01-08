package com.primihub.biz.service.sys;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.base.PageDataEntity;
import com.primihub.biz.entity.sys.param.FindWhitelistPageParam;
import com.primihub.biz.entity.sys.param.SaveOrUpdateWhitelistParam;
import com.primihub.biz.entity.sys.po.SysUserWhitelist;
import com.primihub.biz.entity.sys.vo.SysUserWhitelistVO;
import com.primihub.biz.repository.primarydb.sys.SysUserWhitelistPrimarydbRepository;
import com.primihub.biz.repository.secondarydb.sys.SysUserWhitelistSecondarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 用户白名单服务类
 */
@Slf4j
@Service
public class SysUserWhitelistService {

    /**
     * 邮箱格式正则表达式
     */
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");

    /**
     * 手机号格式正则表达式（中国大陆）
     */
    private static final Pattern PHONE_PATTERN =
            Pattern.compile("^1[3-9]\\d{9}$");

    @Autowired
    private SysUserWhitelistPrimarydbRepository primaryRepository;

    @Autowired
    private SysUserWhitelistSecondarydbRepository secondaryRepository;

    /**
     * 保存或更新白名单
     *
     * @param param    参数
     * @param userId   用户ID
     * @param userName 用户名
     * @return 操作结果
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity saveOrUpdateWhitelist(
            SaveOrUpdateWhitelistParam param,
            Long userId,
            String userName) {

        try {
            // 1. 参数校验
            if (param.getWhitelistType() == null ||
                    (param.getWhitelistType() != 1 && param.getWhitelistType() != 2)) {
                return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "白名单类型无效");
            }

            if (param.getWhitelistValue() == null || param.getWhitelistValue().trim().isEmpty()) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM, "白名单值不能为空");
            }

            String value = param.getWhitelistValue().trim();

            // 2. 格式校验
            if (param.getWhitelistType() == 1) {
                // 邮箱格式校验
                if (!EMAIL_PATTERN.matcher(value).matches()) {
                    return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "邮箱格式不正确");
                }
            } else if (param.getWhitelistType() == 2) {
                // 手机号格式校验
                if (!PHONE_PATTERN.matcher(value).matches()) {
                    return BaseResultEntity.failure(BaseResultEnum.PARAM_INVALIDATION, "手机号格式不正确");
                }
            }

            // 3. 重复性校验
            SysUserWhitelist existing = secondaryRepository.selectWhitelistByTypeAndValue(
                    param.getWhitelistType(), value);

            if (param.getWhitelistId() == null) {
                // 新增模式
                if (existing != null) {
                    return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE,
                            "该白名单值已存在");
                }

                SysUserWhitelist whitelist = new SysUserWhitelist();
                whitelist.setWhitelistType(param.getWhitelistType());
                whitelist.setWhitelistValue(value);
                whitelist.setWhitelistDesc(param.getWhitelistDesc());
                whitelist.setStatus(param.getStatus() != null ? param.getStatus() : 1);
                whitelist.setCreatorId(userId);
                whitelist.setCreatorName(userName);

                int result = primaryRepository.insertWhitelist(whitelist);
                return result > 0 ?
                        BaseResultEntity.success() :
                        BaseResultEntity.failure(BaseResultEnum.DATA_SAVE_FAIL);

            } else {
                // 更新模式
                if (existing != null && !existing.getWhitelistId().equals(param.getWhitelistId())) {
                    return BaseResultEntity.failure(BaseResultEnum.NON_REPEATABLE,
                            "该白名单值已被其他记录使用");
                }

                SysUserWhitelist whitelist = secondaryRepository.selectWhitelistById(
                        param.getWhitelistId());

                if (whitelist == null) {
                    return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL);
                }

                whitelist.setWhitelistType(param.getWhitelistType());
                whitelist.setWhitelistValue(value);
                whitelist.setWhitelistDesc(param.getWhitelistDesc());
                whitelist.setStatus(param.getStatus());

                int result = primaryRepository.updateWhitelist(whitelist);
                return result > 0 ?
                        BaseResultEntity.success() :
                        BaseResultEntity.failure(BaseResultEnum.DATA_EDIT_FAIL);
            }

        } catch (Exception e) {
            log.error("保存白名单失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 删除白名单（软删除）
     *
     * @param whitelistId 白名单ID
     * @return 操作结果
     */
    @Transactional(rollbackFor = Exception.class)
    public BaseResultEntity deleteWhitelist(Long whitelistId) {
        try {
            if (whitelistId == null) {
                return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM);
            }

            SysUserWhitelist whitelist = secondaryRepository.selectWhitelistById(whitelistId);
            if (whitelist == null) {
                return BaseResultEntity.failure(BaseResultEnum.DATA_QUERY_NULL);
            }

            int result = primaryRepository.deleteWhitelist(whitelistId);
            return result > 0 ?
                    BaseResultEntity.success() :
                    BaseResultEntity.failure(BaseResultEnum.DATA_DEL_FAIL);

        } catch (Exception e) {
            log.error("删除白名单失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 分页查询白名单列表
     *
     * @param findParam 查询参数
     * @param pageNum   页码
     * @param pageSize  每页大小
     * @return 分页结果
     */
    public BaseResultEntity findWhitelistPage(
            FindWhitelistPageParam findParam,
            Integer pageNum,
            Integer pageSize) {

        try {
            Map<String, Object> paramMap = new HashMap<>();
            paramMap.put("whitelistType", findParam.getWhitelistType());
            paramMap.put("whitelistValue", findParam.getWhitelistValue());
            paramMap.put("status", findParam.getStatus());
            paramMap.put("pageIndex", (pageNum - 1) * pageSize);
            paramMap.put("pageSize", pageSize);

            List<SysUserWhitelistVO> list = secondaryRepository.selectWhitelistPage(paramMap);
            Long total = secondaryRepository.selectWhitelistCount(paramMap);

            PageDataEntity pageData = new PageDataEntity(
                    total.intValue(),
                    pageSize,
                    pageNum,
                    list
            );

            return BaseResultEntity.success(pageData);

        } catch (Exception e) {
            log.error("查询白名单列表失败", e);
            return BaseResultEntity.failure(BaseResultEnum.FAILURE, e.getMessage());
        }
    }

    /**
     * 检查用户是否在白名单中（用于注册/登录验证）
     *
     * @param whitelistType  白名单类型
     * @param whitelistValue 白名单值
     * @return true=在白名单中，false=不在白名单中
     */
    public boolean isUserInWhitelist(Integer whitelistType, String whitelistValue) {
        try {
            Integer count = secondaryRepository.checkUserInWhitelist(whitelistType, whitelistValue);
            return count != null && count > 0;
        } catch (Exception e) {
            log.error("检查白名单失败", e);
            return false;
        }
    }
}
