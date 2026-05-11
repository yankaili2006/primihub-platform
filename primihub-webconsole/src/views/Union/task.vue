<template>
  <div class="container">
    <el-page-header content="联邦求并任务" style="margin-bottom: 20px;" @back="$router.push({name:'UnionList'})" />
    <el-steps :active="stepActive" align-center finish-status="success" style="margin-bottom: 32px;">
      <el-step title="基础信息" icon="el-icon-edit" />
      <el-step title="数据引入" icon="el-icon-upload" />
      <el-step title="高级配置" icon="el-icon-setting" />
    </el-steps>
    <div class="step" v-show="stepActive === 0">
      <div class="inner-con">
        <el-form ref="form" :model="formData" :rules="rules" label-width="140px">
          <el-form-item label="任务名称" prop="taskName">
            <el-input v-model="formData.taskName" maxlength="32" show-word-limit placeholder="请输入任务名称,限32字" @input="autoFillResultName" />
          </el-form-item>
          <el-form-item label="求并结果名称" prop="resultName">
            <el-input v-model="formData.resultName" placeholder="默认自动填充为任务名称" />
          </el-form-item>
        </el-form>
      </div>
      <div style="text-align: center; margin: 24px 0;">
        <el-button type="primary" @click="stepActive = 1">下一步</el-button>
      </div>
    </div>
    <div class="step" v-show="stepActive === 1">
      <div class="inner-con inner-con-second">
        <el-form ref="formData" :model="formData" :rules="rules" label-width="0px">
          <div class="flex organ-title">
            <div><i class="el-icon-user-solid" style="color:#409eff;" /> 发起方</div>
            <div><i class="el-icon-share" style="color:#67c23a;" /> 协作方</div>
          </div>
          <div class="header">
            <div class="organ-container">
              <div class="row-title"><span>参与机构</span></div>
              <div class="organ-container-right flex">
                <div class="organ">
                  <el-select v-model="formData.ownOrganName" class="organ-select" disabled placeholder="本机构" />
                </div>
                <div class="content-organ">并</div>
                <div class="organ">
                  <el-select v-model="formData.otherOrganId" placeholder="请选择协作方" @change="onOtherOrganChange">
                    <el-option v-for="item in organList" :key="item.globalId" :label="item.globalName" :value="item.globalId" />
                  </el-select>
                </div>
              </div>
            </div>
          </div>
          <div class="item-row">
            <div class="item flex">
              <div class="row-title"><span>资源表</span></div>
              <div class="row-right-container justify-content-between flex">
                <el-form-item prop="ownResourceId">
                  <el-select v-model="formData.ownResourceName" placeholder="发起方资源表" clearable @focus="openDialog('own')" @clear="handleResourceClear('own')" />
                </el-form-item>
                <div class="right-container-center"><el-tag type="info" size="mini">VS</el-tag></div>
                <el-form-item prop="otherResourceId">
                  <el-select v-model="formData.otherResourceName" placeholder="协作方资源表" @focus="openDialog('other')" />
                </el-form-item>
              </div>
            </div>
            <div class="item flex">
              <div class="row-title"><span>关联键</span></div>
              <div class="row-right-container justify-content-between flex">
                <el-form-item prop="ownKeyword">
                  <el-select v-model="formData.ownKeyword" multiple placeholder="发起方关联键">
                    <el-option v-for="(item,idx) in ownOrganResourceField" :key="idx" :label="item.fieldName" :value="item.fieldName" />
                  </el-select>
                </el-form-item>
                <div class="right-container-center"><el-tag type="info" size="mini">VS</el-tag></div>
                <el-form-item prop="otherKeyword">
                  <el-select v-model="formData.otherKeyword" multiple placeholder="协作方关联键">
                    <el-option v-for="(item,idx) in otherOrganResourceField" :key="idx" :label="item.fieldName" :value="item.fieldName" />
                  </el-select>
                </el-form-item>
              </div>
            </div>
          </div>
        </el-form>
      </div>
      <div style="text-align: center; margin: 24px 0;">
        <el-button @click="stepActive = 0">上一步</el-button>
        <el-button type="primary" @click="stepActive = 2">下一步</el-button>
      </div>
    </div>
    <div class="step" v-show="stepActive === 2">
      <div class="inner-con inner-con-high">
        <el-form ref="highForm" :model="formData" label-width="140px">
          <el-form-item label="结果获取方" prop="resultOrganIds">
            <el-checkbox-group v-model="selectedResultOrgans">
              <el-checkbox :label="formData.ownOrganId" disabled>{{ formData.ownOrganName }} (发起方)</el-checkbox>
              <el-checkbox v-if="formData.otherOrganId" :label="formData.otherOrganId">{{ getOrganName(formData.otherOrganId) }} (协作方)</el-checkbox>
            </el-checkbox-group>
          </el-form-item>
          <el-form-item label="实现方法" prop="tag">
            <el-radio-group v-model="formData.tag">
              <el-radio-button :label="0">ECDH</el-radio-button>
              <el-radio-button :label="1">KKRT</el-radio-button>
              <el-radio-button :label="2">TEE</el-radio-button>
            </el-radio-group>
            <div class="form-tip" style="margin-top: 8px;">ECDH: 基于椭圆曲线DH密钥交换; KKRT: 基于OT扩展; TEE: 基于可信执行环境</div>
          </el-form-item>
          <el-form-item v-if="formData.tag == 2" label="可信计算节点" prop="teeOrganId">
            <el-select v-model="formData.teeOrganId" placeholder="请选择可信计算节点">
              <el-option v-for="item in teeOrganList" :key="item.globalId" :label="item.globalName" :value="item.globalId" />
            </el-select>
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="formData.remarks" type="textarea" resize="none" maxlength="200" show-word-limit placeholder="可选，备注信息" />
          </el-form-item>
        </el-form>
      </div>
      <div style="text-align: center; margin: 24px 0;">
        <el-button @click="stepActive = 1">上一步</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">提交任务</el-button>
      </div>
    </div>
    <el-dialog title="选择资源" :visible.sync="dialogVisible" top="10px" width="800px" :before-close="handleDialogCancel">
      <div class="dialog-body">
        <div class="search-input">
          <el-input v-model="searchKeyword" placeholder="搜索资源名称" @keyup.enter.native="searchResource">
            <el-button slot="append" icon="el-icon-search" @click="searchResource" />
          </el-input>
        </div>
        <ResourceTableSingleSelect max-height="560" :data="resourceList" :show-status="false" :selected-data="selectResources && selectResources.resourceId" @change="handleResourceChange" />
      </div>
      <div slot="footer">
        <el-button @click="handleDialogCancel">取消</el-button>
        <el-button type="primary" @click="handleDialogSubmit">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { saveDataUnion } from '@/api/union'
import { getResourceList } from '@/api/fusionResource'
import { getAvailableOrganList } from '@/api/center'
import ResourceTableSingleSelect from '@/components/ResourceTableSingleSelect'

export default {
  name: 'UnionTask',
  components: { ResourceTableSingleSelect },
  data() {
    return {
      stepActive: 0, role: '', resourceList: [], searchKeyword: '',
      selectResources: null, dialogVisible: false,
      allOrganList: [], organList: [], teeOrganList: [],
      ownOrganResourceField: [], otherOrganResourceField: [],
      selectedResultOrgans: [], submitting: false,
      formData: {
        taskName: '', ownOrganId: 0, ownResourceId: '', ownKeyword: [],
        otherOrganId: '', otherResourceId: '', otherKeyword: [],
        resultName: '', resultOrganIds: '', tag: 0, teeOrganId: '', remarks: ''
      },
      ownResourceName: '', otherResourceName: '',
      rules: {
        taskName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
        resultName: [{ required: true, message: '请输入结果名称' }],
        ownResourceId: [{ required: true, message: '请选择资源' }],
        ownKeyword: [{ required: true, message: '请选择关联键', trigger: 'blur' }],
        otherResourceId: [{ required: true, message: '请选择资源' }],
        otherKeyword: [{ required: true, message: '请选择关联键', trigger: 'blur' }],
        tag: [{ required: true, message: '请选择实现方法' }]
      }
    }
  },
  computed: { centerImg() { return require('@/assets/intersection.svg') } },
  async created() {
    this.formData.ownOrganId = this.$store.getters.userOrganId
    this.formData.ownOrganName = this.$store.getters.userOrganName
    this.selectedResultOrgans = [this.formData.ownOrganId]
    await this.getAvailableOrganList()
  },
  methods: {
    autoFillResultName() {
      if (!this.formData.resultName) this.formData.resultName = this.formData.taskName + '_并集结果'
    },
    getOrganName(id) {
      const found = this.allOrganList.find(item => item.globalId === id)
      return found ? found.globalName : id
    },
    async getAvailableOrganList() {
      const res = await getAvailableOrganList()
      if (res.code === 0) this.allOrganList = this.organList = res.result
    },
    onOtherOrganChange(val) {
      if (val) this.teeOrganList = this.allOrganList.filter(item => item.globalId !== val)
    },
    openDialog(role) {
      if (role === 'other' && !this.formData.otherOrganId) { this.$message.error('请先选择协作方'); return }
      this.role = role; this.searchKeyword = ''; this.dialogVisible = true; this.getResourceList()
    },
    async getResourceList() {
      const params = { pageNo: 1, pageSize: 100, organId: this.role === 'own' ? this.formData.ownOrganId : this.formData.otherOrganId, resourceName: this.searchKeyword }
      const { code, result } = await getResourceList(params)
      if (code === 0) this.resourceList = result.data || []
    },
    handleResourceChange(data) { this.selectResources = data },
    handleDialogSubmit() {
      if (!this.selectResources) { this.$message.warning('请选择资源'); return }
      if (this.role === 'own') {
        this.ownOrganResourceField = this.selectResources.fieldList || []
        this.formData.ownKeyword = []; this.formData.ownResourceId = this.selectResources.resourceId
        this.formData.ownResourceName = this.selectResources.resourceName
      } else {
        this.otherOrganResourceField = this.selectResources.fieldList || []
        this.formData.otherKeyword = []; this.formData.otherResourceId = this.selectResources.resourceId
        this.formData.otherResourceName = this.selectResources.resourceName
      }
      this.dialogVisible = false
    },
    handleDialogCancel() { this.dialogVisible = false; this.searchKeyword = '' },
    searchResource() { this.getResourceList() },
    handleResourceClear(role) {
      if (role === 'own') {
        this.formData.ownResourceId = ''; this.formData.ownResourceName = ''; this.formData.ownKeyword = []; this.ownOrganResourceField = []
      } else {
        this.formData.otherResourceId = ''; this.formData.otherResourceName = ''; this.otherOrganResourceField = []; this.formData.otherKeyword = []
      }
    },
    handleSubmit() {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.stepActive = 0; return }
        this.submitting = true
        const data = {
          ...this.formData,
          ownKeyword: this.formData.ownKeyword.join(','),
          otherKeyword: this.formData.otherKeyword.join(','),
          resultOrganIds: this.selectedResultOrgans.join(',')
        }
        const res = await saveDataUnion(data)
        this.submitting = false
        if (res.code === 0) {
          this.$notify({ title: '创建成功', message: '联邦求并任务已创建，正在跳转详情页...', type: 'success', duration: 2000 })
          setTimeout(() => this.$router.push({ name: 'UnionDetail', params: { id: res.result } }), 1000)
        }
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import "../../styles/variables.module.scss";
.container { overflow: hidden; background: #fff; padding: 36px; border-radius: 8px; }
.inner-con { background: #fff; margin: 32px 0; ::v-deep .el-form { width: 950px; margin: 0 auto; } }
.form-tip { font-size: 12px; color: #909399; margin-top: 4px; line-height: 1.5; }
.row-title { width: 140px; align-self: center; font-size: 14px; color: #333; flex-shrink: 0; text-align: right; padding-right: 12px; font-weight: 700;
  span:before { content: '*'; color: #f56c6c; margin-right: 4px; }
}
.inner-con-second {
  ::v-deep .el-select input, ::v-deep .el-input input { border: none; }
  .organ-title { padding-left: 160px; width: 100%; margin: 32px 0 24px 0;
    div { flex: 1; color: #333; font-size: 16px; font-weight: 700; &:last-child { padding-left: 70px; } }
  }
  .row-right-container { flex: 1; border: 1px solid #ccc; border-radius: 4px; padding: 0 10px;
    ::v-deep .el-form-item { margin-bottom: 0; flex: 1; .el-select { width: 90%; } &:last-child .el-select { float: right; } }
    .right-container-center { width: 32px; align-self: center; margin: 0 12px; text-align: center; }
  }
}
.inner-con-high { ::v-deep input { width: 340px; } ::v-deep .el-radio-button__inner { min-width: 100px; } }
.header { position: relative; height: 40px; margin-bottom: 20px;
  .organ-container { display: flex; justify-content: space-between;
    .organ-container-right { flex: 1; border: 1px solid #ccc; border-radius: 4px; padding: 0 10px; justify-content: space-between;
      .content-organ { align-self: center; font-size: 12px; background: #F6F6F6; color: $mainColor; padding: 5px 10px; border-radius: 2px; margin: 0 12px; flex-shrink: 0; }
    }
  }
  .organ { background-color: #fff; font-size: 14px; font-weight: bold; flex: 1;
    &:last-child ::v-deep .el-select { float: right; } ::v-deep .el-select { width: 90%; }
  }
}
.item-row { margin: 0 auto; .item { margin-bottom: 22px; } }
.search-input { width: 300px; }
</style>
