package com.primihub.application.controller.data;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.data.req.DataResourceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceReq;
import com.primihub.biz.entity.data.req.TrustedSpaceResourceReq;
import com.primihub.biz.service.data.DataTrustedSpaceService;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.Arrays;
import java.util.Collections;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class TrustedSpaceControllerTest {

    @Mock
    private DataTrustedSpaceService service;

    @InjectMocks
    private TrustedSpaceController controller;

    private BaseResultEntity ok;

    @Before
    public void setUp() {
        ok = BaseResultEntity.success();
    }

    /** Integer 对 Integer 比较，避免 assertEquals(int, Integer) 的重载歧义 */
    private static Integer code(BaseResultEntity r) {
        return r.getCode();
    }

    // ---------- page ----------
    @Test
    public void page_passThrough() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setPageNo(2);
        req.setPageSize(10);
        when(service.page(req)).thenReturn(ok);
        assertSame(ok, controller.page(req));
        verify(service).page(req);
    }

    @Test
    public void page_invalidPageSize_rejected() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setPageSize(0);
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), code(controller.page(req)));
        verify(service, never()).page(any());
    }

    @Test
    public void page_nullReq_usesDefaults() {
        when(service.page(any(TrustedSpaceReq.class))).thenReturn(ok);
        assertSame(ok, controller.page(null));
    }

    // ---------- listAll / detail ----------
    @Test
    public void listAll_passThrough() {
        when(service.listAll()).thenReturn(ok);
        assertSame(ok, controller.listAll());
    }

    @Test
    public void detail_missingId_lackOfParam() {
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.detail(null)));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.detail(0L)));
        verify(service, never()).detail(anyLong());
    }

    @Test
    public void detail_passThrough() {
        when(service.detail(1001L)).thenReturn(ok);
        assertSame(ok, controller.detail(1001L));
    }

    // ---------- save / update ----------
    @Test
    public void save_blankName_lackOfParam() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("   ");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.save(req, 1L)));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.save(null, 1L)));
        verify(service, never()).save(any(), anyLong());
    }

    @Test
    public void save_passThrough() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("水利");
        when(service.save(req, 7L)).thenReturn(ok);
        assertSame(ok, controller.save(req, 7L));
        verify(service).save(req, 7L);
    }

    @Test
    public void update_missingId_lackOfParam() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("x");
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.update(req, 1L)));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.update(null, 1L)));
        verify(service, never()).update(any(), anyLong());
    }

    @Test
    public void update_passThrough() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(1002L);
        when(service.update(req, 1L)).thenReturn(ok);
        assertSame(ok, controller.update(req, 1L));
    }

    // ---------- delete ----------
    @Test
    public void delete_missingId_lackOfParam() {
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.delete(null)));
        verify(service, never()).delete(anyLong());
    }

    @Test
    public void delete_passThrough() {
        when(service.delete(1002L)).thenReturn(ok);
        assertSame(ok, controller.delete(1002L));
    }

    // ---------- assign / remove ----------
    @Test
    public void assign_validation() {
        TrustedSpaceResourceReq noSpace = new TrustedSpaceResourceReq();
        noSpace.setResourceIds(Arrays.asList(1L, 2L));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.assignResources(noSpace)));

        TrustedSpaceResourceReq noIds = new TrustedSpaceResourceReq();
        noIds.setSpaceId(1002L);
        noIds.setResourceIds(Collections.emptyList());
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.assignResources(noIds)));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.assignResources(null)));
        verify(service, never()).assignResources(any());
    }

    @Test
    public void assign_passThrough() {
        TrustedSpaceResourceReq req = new TrustedSpaceResourceReq();
        req.setSpaceId(1002L);
        req.setResourceIds(Arrays.asList(1L, 2L));
        when(service.assignResources(req)).thenReturn(ok);
        assertSame(ok, controller.assignResources(req));
    }

    @Test
    public void remove_validationAndPassThrough() {
        TrustedSpaceResourceReq bad = new TrustedSpaceResourceReq();
        bad.setSpaceId(1002L);
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.removeResources(bad)));
        verify(service, never()).removeResources(any());

        bad.setResourceIds(Collections.singletonList(5L));
        when(service.removeResources(bad)).thenReturn(ok);
        assertSame(ok, controller.removeResources(bad));
    }

    // ---------- resources ----------
    @Test
    public void resources_missingSpace_lackOfParam() {
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), code(controller.resources(null, new DataResourceReq(), 1L)));
        verify(service, never()).resourcePage(anyLong(), any(), anyLong());
    }

    @Test
    public void resources_passThrough() {
        DataResourceReq req = new DataResourceReq();
        when(service.resourcePage(1002L, req, 3L)).thenReturn(ok);
        assertSame(ok, controller.resources(1002L, req, 3L));
    }
}
