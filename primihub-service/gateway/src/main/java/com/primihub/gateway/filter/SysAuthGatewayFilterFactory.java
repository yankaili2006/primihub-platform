package com.primihub.gateway.filter;

import com.primihub.biz.config.base.BaseConfiguration;
import com.primihub.biz.entity.base.BaseParamEnum;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.vo.SysAuthNodeVO;
import com.primihub.biz.entity.sys.vo.SysUserListVO;
import com.primihub.biz.repository.primaryredis.sys.SysUserPrimaryRedisRepository;
import com.primihub.biz.repository.secondarydb.sys.SysRoleSecondarydbRepository;
import com.primihub.biz.service.sys.SysAuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.core.annotation.Order;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Slf4j
@Order(11)
@Component
public class SysAuthGatewayFilterFactory extends AbstractGatewayFilterFactory {

    @Autowired
    private SysUserPrimaryRedisRepository sysUserPrimaryRedisRepository;
    @Autowired
    private SysAuthService sysAuthService;
    @Autowired
    private SysRoleSecondarydbRepository sysRoleSecondarydbRepository;
    @Autowired
    private BaseConfiguration baseConfiguration;

    @Override
    public GatewayFilter apply(Object config) {
        return (((exchange, chain) -> {
            String token=exchange.getAttribute(BaseParamEnum.TOKEN.getColumnName());
            if(token==null|| "".equals(token)) {
                return chain.filter(exchange).then();
            }

            String userIdStr;
            String rawPath = exchange.getRequest().getURI().getRawPath();
            if(token.equals(baseConfiguration.getUsefulToken())){
                userIdStr="1";
            }else {
                SysUserListVO sysUserListVO = sysUserPrimaryRedisRepository.findUserLoginStatus(token);
                if (sysUserListVO == null) {
                    return GatewayFilterFactoryTool.writeFailureJsonToResponse(exchange, BaseResultEnum.TOKEN_INVALIDATION);
                }
                sysUserPrimaryRedisRepository.expireUserLoginStatus(token, sysUserListVO.getUserId());

                Set<Long> roleIdSet= Stream.of(sysUserListVO.getRoleIdList().split(",")).filter(item->!"".equals(item))
                        .map(item->(Long.parseLong(item))).collect(Collectors.toSet());
                Set<Long> authIdList = sysRoleSecondarydbRepository.selectRaByBatchRoleId(roleIdSet);
                Map<String, SysAuthNodeVO> mapping = sysAuthService.getSysAuthUrlMapping();
                SysAuthNodeVO sysAuthNodeVO = mapping.get(rawPath);

                // ========== 权限验证调试日志 START ==========
                log.info("=== 权限验证调试信息 ===");
                log.info("请求路径: {}", rawPath);
                log.info("用户ID: {}, 用户账号: {}", sysUserListVO.getUserId(), sysUserListVO.getUserAccount());
                log.info("用户角色ID列表: {}", sysUserListVO.getRoleIdList());
                log.info("角色ID集合: {}", roleIdSet);
                log.info("角色权限ID集合: {}", authIdList);
                log.info("用户权限ID列表(字符串): {}", sysUserListVO.getAuthIdList());
                log.info("URL映射中的权限节点: {}", sysAuthNodeVO);

                if (sysAuthNodeVO != null) {
                    log.info("所需权限ID: {}", sysAuthNodeVO.getAuthId());
                    log.info("权限名称: {}, URL: {}", sysAuthNodeVO.getAuthName(), sysAuthNodeVO.getAuthUrl());

                    boolean userHasAuth = sysUserListVO.getAuthIdList().contains(sysAuthNodeVO.getAuthId().toString());
                    boolean roleHasAuth = authIdList.contains(sysAuthNodeVO.getAuthId());

                    log.info("用户是否拥有该权限: {}", userHasAuth);
                    log.info("角色是否拥有该权限: {}", roleHasAuth);

                    if (!userHasAuth && !roleHasAuth) {
                        log.warn("⚠️ 权限验证失败！用户和角色都没有权限ID: {}", sysAuthNodeVO.getAuthId());
                        log.warn("用户权限列表: {}", sysUserListVO.getAuthIdList());
                        log.warn("角色权限列表: {}", authIdList);
                        return GatewayFilterFactoryTool.writeFailureJsonToResponse(exchange, BaseResultEnum.NO_AUTH);
                    } else {
                        log.info("✓ 权限验证通过");
                    }
                } else {
                    log.info("该URL未在权限系统中注册，跳过权限检查");
                }
                log.info("=== 权限验证调试信息结束 ===");
                // ========== 权限验证调试日志 END ==========

                userIdStr = sysUserListVO.getUserId().toString();
            }
            ServerHttpRequest newRequest = exchange.getRequest().mutate()
                    .header("userId", userIdStr)
                    .header("token", token)
                    .build();
            return chain.filter(exchange.mutate().request(newRequest).build());
        }));
    }
}
