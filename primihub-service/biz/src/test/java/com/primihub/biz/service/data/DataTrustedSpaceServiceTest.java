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
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.*;

import static org.junit.Assert.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.Silent.class)
public class DataTrustedSpaceServiceTest {

    @Mock
    private DataTrustedSpaceRepository repo;
    @Mock
    private DataTrustedSpacePrRepository prRepo;
    @Mock
    private OrganConfiguration organConfiguration;
    @Mock
    private DataResourceService dataResourceService;

    @InjectMocks
    private DataTrustedSpaceService service;

    @Captor
    private ArgumentCaptor<DataTrustedSpace> spaceCaptor;
    @Captor
    private ArgumentCaptor<List<Long>> idsCaptor;
    @Captor
    private ArgumentCaptor<DataResourceReq> resourceReqCaptor;

    private static DataTrustedSpace space(long id, String code, String name, int isDefault, int status) {
        DataTrustedSpace s = new DataTrustedSpace();
        s.setSpaceId(id);
        s.setSpaceCode(code);
        s.setSpaceName(name);
        s.setIsDefault(isDefault);
        s.setStatus(status);
        s.setSortIndex(100);
        return s;
    }

    private static Map<String, Object> cnt(Object spaceId, long c) {
        Map<String, Object> m = new HashMap<>();
        m.put("spaceId", spaceId);
        m.put("cnt", c);
        return m;
    }

    // ---------- save ----------
    @Test
    public void save_fillsOrganDefaultsAndGeneratesCode() {
        when(organConfiguration.getSysLocalOrganId()).thenReturn("organ-A");
        when(organConfiguration.getSysLocalOrganName()).thenReturn("机构A");
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("  水利  ");
        req.setSpaceDesc("desc");

        BaseResultEntity r = service.save(req, 9L);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        verify(prRepo).insertTrustedSpace(spaceCaptor.capture());
        DataTrustedSpace po = spaceCaptor.getValue();
        assertEquals("水利", po.getSpaceName());
        assertTrue(po.getSpaceCode(), DataTrustedSpaceService.CODE_PATTERN.matcher(po.getSpaceCode()).matches());
        assertTrue(po.getSpaceCode().startsWith("ts_"));
        assertEquals("organ-A", po.getOrganId());
        assertEquals("机构A", po.getOrganName());
        assertEquals(Integer.valueOf(0), po.getIsDefault());
        assertEquals(Integer.valueOf(1), po.getStatus());
        assertEquals(Integer.valueOf(100), po.getSortIndex());
        assertEquals(Long.valueOf(9L), po.getUserId());
    }

    @Test
    public void save_duplicateName_nonRepeatable() {
        when(repo.selectTrustedSpaceByName(eq("水利"), isNull())).thenReturn(space(1002, "water", "水利", 0, 1));
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("水利");
        req.setSpaceCode("water2");
        assertEquals(BaseResultEnum.NON_REPEATABLE.getReturnCode(), service.save(req, 1L).getCode());
        verify(prRepo, never()).insertTrustedSpace(any());
    }

    @Test
    public void save_duplicateCode_nonRepeatable() {
        when(repo.selectTrustedSpaceByCode(eq("water"), isNull())).thenReturn(space(1002, "water", "水利", 0, 1));
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("水利二");
        req.setSpaceCode("water");
        assertEquals(BaseResultEnum.NON_REPEATABLE.getReturnCode(), service.save(req, 1L).getCode());
        verify(prRepo, never()).insertTrustedSpace(any());
    }

    @Test
    public void save_badCodeOrStatus_paramInvalidation() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceName("x");
        req.setSpaceCode("bad code!");
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), service.save(req, 1L).getCode());
        req.setSpaceCode("ok_code");
        req.setStatus(5);
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), service.save(req, 1L).getCode());
        verify(prRepo, never()).insertTrustedSpace(any());
    }

    // ---------- update ----------
    @Test
    public void update_defaultSpace_cannotDisableOrChangeCode() {
        when(repo.selectTrustedSpaceById(1001L)).thenReturn(space(1001, "primihub", "PrimiHub", 1, 1));
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(1001L);
        req.setStatus(0);
        assertEquals(BaseResultEnum.CAN_NOT_ALTER.getReturnCode(), service.update(req, 1L).getCode());

        TrustedSpaceReq req2 = new TrustedSpaceReq();
        req2.setSpaceId(1001L);
        req2.setSpaceCode("other");
        assertEquals(BaseResultEnum.CAN_NOT_ALTER.getReturnCode(), service.update(req2, 1L).getCode());
        verify(prRepo, never()).updateTrustedSpace(any());
    }

    @Test
    public void update_renameWithDuplicate_nonRepeatable() {
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        when(repo.selectTrustedSpaceByName("农业", 1002L)).thenReturn(space(1004, "agri", "农业", 0, 1));
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(1002L);
        req.setSpaceName("农业");
        assertEquals(BaseResultEnum.NON_REPEATABLE.getReturnCode(), service.update(req, 1L).getCode());
        verify(prRepo, never()).updateTrustedSpace(any());
    }

    @Test
    public void update_noChange_lackOfParam() {
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(1002L);
        req.setSpaceName("水利"); // same name
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), service.update(req, 1L).getCode());
    }

    @Test
    public void update_success_onlyChangedFieldsSet() {
        DataTrustedSpace exist = space(1002, "water", "水利", 0, 1);
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(exist);
        when(repo.countResourcesBySpace(1002L, 0)).thenReturn(3);
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(1002L);
        req.setSpaceDesc("new desc");
        req.setStatus(0);
        BaseResultEntity r = service.update(req, 1L);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        verify(prRepo).updateTrustedSpace(spaceCaptor.capture());
        DataTrustedSpace upd = spaceCaptor.getValue();
        assertEquals(Long.valueOf(1002L), upd.getSpaceId());
        assertNull(upd.getSpaceName());
        assertNull(upd.getSpaceCode());
        assertEquals("new desc", upd.getSpaceDesc());
        assertEquals(Integer.valueOf(0), upd.getStatus());
        assertEquals(3, ((DataTrustedSpaceVo) r.getResult()).getResourceCount().intValue());
    }

    @Test
    public void update_missing_dataQueryNull() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setSpaceId(42L);
        req.setSpaceName("x");
        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), service.update(req, 1L).getCode());
    }

    // ---------- delete ----------
    @Test
    public void delete_default_refused() {
        when(repo.selectTrustedSpaceById(1001L)).thenReturn(space(1001, "primihub", "PrimiHub", 1, 1));
        assertEquals(BaseResultEnum.CAN_NOT_DELETE.getReturnCode(), service.delete(1001L).getCode());
        verify(prRepo, never()).deleteTrustedSpace(anyLong());
        verify(prRepo, never()).clearResourceTrustedSpace(anyLong(), any());
    }

    @Test
    public void delete_movesResourcesToDefaultThenSoftDeletes() {
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        when(prRepo.clearResourceTrustedSpace(1002L, null)).thenReturn(4);
        BaseResultEntity r = service.delete(1002L);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        @SuppressWarnings("unchecked")
        Map<String, Object> result = (Map<String, Object>) r.getResult();
        assertEquals(4, result.get("movedResources"));
        verify(prRepo).clearResourceTrustedSpace(1002L, null);
        verify(prRepo).deleteTrustedSpace(1002L);
    }

    @Test
    public void delete_missing_dataQueryNull() {
        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), service.delete(99L).getCode());
    }

    // ---------- assign / remove ----------
    @Test
    public void assign_dedupesIdsAndDropsInvalid() {
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        when(prRepo.updateResourceTrustedSpace(eq(1002L), anyList())).thenReturn(2);
        TrustedSpaceResourceReq req = new TrustedSpaceResourceReq();
        req.setSpaceId(1002L);
        req.setResourceIds(Arrays.asList(5L, 5L, null, 0L, -1L, 7L));
        BaseResultEntity r = service.assignResources(req);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        verify(prRepo).updateResourceTrustedSpace(eq(1002L), idsCaptor.capture());
        assertEquals(Arrays.asList(5L, 7L), idsCaptor.getValue());
    }

    @Test
    public void assign_disabledSpace_rejected() {
        when(repo.selectTrustedSpaceById(1003L)).thenReturn(space(1003, "nev", "新能源车", 0, 0));
        TrustedSpaceResourceReq req = new TrustedSpaceResourceReq();
        req.setSpaceId(1003L);
        req.setResourceIds(Collections.singletonList(5L));
        assertEquals(BaseResultEnum.PARAM_INVALIDATION.getReturnCode(), service.assignResources(req).getCode());
        verify(prRepo, never()).updateResourceTrustedSpace(anyLong(), anyList());
    }

    @Test
    public void assign_emptyIds_lackOfParam() {
        TrustedSpaceResourceReq req = new TrustedSpaceResourceReq();
        req.setSpaceId(1002L);
        req.setResourceIds(Arrays.asList(null, 0L));
        assertEquals(BaseResultEnum.LACK_OF_PARAM.getReturnCode(), service.assignResources(req).getCode());
    }

    @Test
    public void remove_fromDefault_refused_otherwiseClears() {
        when(repo.selectTrustedSpaceById(1001L)).thenReturn(space(1001, "primihub", "PrimiHub", 1, 1));
        TrustedSpaceResourceReq req = new TrustedSpaceResourceReq();
        req.setSpaceId(1001L);
        req.setResourceIds(Collections.singletonList(5L));
        assertEquals(BaseResultEnum.CAN_NOT_ALTER.getReturnCode(), service.removeResources(req).getCode());

        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        when(prRepo.clearResourceTrustedSpace(eq(1002L), anyList())).thenReturn(1);
        req.setSpaceId(1002L);
        BaseResultEntity r = service.removeResources(req);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        verify(prRepo).clearResourceTrustedSpace(eq(1002L), idsCaptor.capture());
        assertEquals(Collections.singletonList(5L), idsCaptor.getValue());
    }

    // ---------- page / listAll / detail ----------
    @Test
    public void page_mergesResourceCounts_nullBucketGoesToDefault() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        req.setPageNo(1);
        req.setPageSize(10);
        when(repo.selectTrustedSpacePage(any())).thenReturn(Arrays.asList(
                space(1001, "primihub", "PrimiHub", 1, 1), space(1002, "water", "水利", 0, 1)));
        when(repo.selectTrustedSpaceCount(any())).thenReturn(2);
        when(repo.selectResourceCountGroupBySpace()).thenReturn(Arrays.asList(
                cnt(null, 100L), cnt(1001L, 3L), cnt(1002L, 2L)));
        BaseResultEntity r = service.page(req);
        assertEquals(BaseResultEnum.SUCCESS.getReturnCode(), r.getCode());
        @SuppressWarnings("unchecked")
        PageDataEntity<DataTrustedSpaceVo> page = (PageDataEntity<DataTrustedSpaceVo>) r.getResult();
        assertEquals(2, page.getTotal());
        assertEquals(103, page.getData().get(0).getResourceCount().intValue());
        assertEquals(2, page.getData().get(1).getResourceCount().intValue());
    }

    @Test
    public void page_empty_returnsEmptyPage() {
        TrustedSpaceReq req = new TrustedSpaceReq();
        when(repo.selectTrustedSpacePage(any())).thenReturn(Collections.emptyList());
        BaseResultEntity r = service.page(req);
        @SuppressWarnings("unchecked")
        PageDataEntity<DataTrustedSpaceVo> page = (PageDataEntity<DataTrustedSpaceVo>) r.getResult();
        assertEquals(0, page.getTotal());
        assertTrue(page.getData().isEmpty());
        verify(repo, never()).selectTrustedSpaceCount(any());
    }

    @Test
    public void detail_missing_dataQueryNull() {
        assertEquals(BaseResultEnum.DATA_QUERY_NULL.getReturnCode(), service.detail(5L).getCode());
    }

    // ---------- resourcePage ----------
    @Test
    public void resourcePage_setsSpaceFilterAndDelegates() {
        when(repo.selectTrustedSpaceById(1001L)).thenReturn(space(1001, "primihub", "PrimiHub", 1, 1));
        BaseResultEntity ok = BaseResultEntity.success();
        when(dataResourceService.getDataResourceList(any(DataResourceReq.class), eq(3L))).thenReturn(ok);
        DataResourceReq req = new DataResourceReq();
        req.setTrustedSpaceName("水利"); // must be cleared, id filter wins
        assertSame(ok, service.resourcePage(1001L, req, 3L));
        verify(dataResourceService).getDataResourceList(resourceReqCaptor.capture(), eq(3L));
        DataResourceReq passed = resourceReqCaptor.getValue();
        assertEquals(Long.valueOf(1001L), passed.getTrustedSpace());
        assertTrue(passed.getTrustedSpaceIncludeDefault());
        assertNull(passed.getTrustedSpaceName());
    }

    @Test
    public void resourcePage_nonDefault_doesNotIncludeNull() {
        when(repo.selectTrustedSpaceById(1002L)).thenReturn(space(1002, "water", "水利", 0, 1));
        when(dataResourceService.getDataResourceList(any(DataResourceReq.class), anyLong())).thenReturn(BaseResultEntity.success());
        service.resourcePage(1002L, null, 1L);
        verify(dataResourceService).getDataResourceList(resourceReqCaptor.capture(), eq(1L));
        assertFalse(resourceReqCaptor.getValue().getTrustedSpaceIncludeDefault());
    }

    // ---------- helpers ----------
    @Test
    public void generateCode_matchesPattern() {
        String c = DataTrustedSpaceService.generateCode();
        assertTrue(c, DataTrustedSpaceService.CODE_PATTERN.matcher(c).matches());
    }
}
