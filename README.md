# openwrt-package-app
国内常用OpenWrt软件包源码合集，每天自动更新，建议使用lean源码

暂时不支持git增量更新（会报错），下次有时间修复下（云编译可以无视）

现在可以使用git pull来更新了

食用方式（18.06）：<br>
 先cd进package目录，然后执行
`git clone https://github.com/liuran001/openwrt-packages`<br>
   
或者添加下面代码到feeds.conf.default文件<br>
`src-git liuran001_packages https://github.com/liuran001/openwrt-packages`<br>
   
先cd进package目录，然后执行<br>
`svn co https://github.com/liuran001/openwrt-packages/branches/packages`<br>
 
源码感谢[liuran001](https://github.com/liuran001/openwrt-packages)<br>

-------------------------------------------------------------------------------
本项目主要用于收藏备份OpenWRT插件，如需使用[liuran001](https://github.com/liuran001/openwrt-packages) | [kenzok8](https://github.com/kenzok8/openwrt-packages)<br>

如要fork，<br>
* 1.请Settings>Developer settings>Personal access tokens设置 {个人访问令牌}<br>
* 2.项目的 Setting>Secrets>{密钥名}，内容填写 {个人访问令牌}<br>
* 3.在upload.yml文件中<br>
   - name: Upload<br>
     env: <br>
      GITHUB_TOKEN: ${{ secrets.密钥名 }}<br>
 
其它请根据自己实际情况修改<br>
 
------------------------------------------------------------------------------
以上设置修改方法是自己搜索摸索出来，如有不对请教教我<br>
