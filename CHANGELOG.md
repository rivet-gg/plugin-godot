# Changelog

## [2.0.0](https://github.com/rivet-gg/plugin-godot/compare/v2.0.0-rc.1...v2.0.0) (2024-08-23)


### Bug Fixes

* install CLI as backup ([#178](https://github.com/rivet-gg/plugin-godot/issues/178)) ([f6310d8](https://github.com/rivet-gg/plugin-godot/commit/f6310d8cb6e8f28a69ce13eb7c1dc060c055a340))


### Chores

* release 2.0.0 ([f12b778](https://github.com/rivet-gg/plugin-godot/commit/f12b77863deacdc6fd3a3b6cbbb50e80e2805585))

## [2.0.0-rc.1](https://github.com/rivet-gg/plugin-godot/compare/v1.4.0...v2.0.0-rc.1) (2024-08-19)


### Features

* add backend env selector ([#144](https://github.com/rivet-gg/plugin-godot/issues/144)) ([9f9238c](https://github.com/rivet-gg/plugin-godot/commit/9f9238c299c43fb653e519d8edd6e4987a1b2ad1))
* add game server panel ([#147](https://github.com/rivet-gg/plugin-godot/issues/147)) ([130c547](https://github.com/rivet-gg/plugin-godot/commit/130c54734c60a7a38bc2717a6b0dc27c5e9353a3))
* add lobbies_server demo ([#145](https://github.com/rivet-gg/plugin-godot/issues/145)) ([c406b1a](https://github.com/rivet-gg/plugin-godot/commit/c406b1a11a5944d09595cfd7223023fe2598378a))
* add opengb generate sdk button ([#141](https://github.com/rivet-gg/plugin-godot/issues/141)) ([243d87d](https://github.com/rivet-gg/plugin-godot/commit/243d87d7bc5453386d3834d6e880537ab35df6f7))
* add report bug button ([#136](https://github.com/rivet-gg/plugin-godot/issues/136)) ([777ae66](https://github.com/rivet-gg/plugin-godot/commit/777ae666652f182157aeca5a0ed2558903313553))
* add setup tab ([#154](https://github.com/rivet-gg/plugin-godot/issues/154)) ([0bf2073](https://github.com/rivet-gg/plugin-godot/commit/0bf20736c6183cfc8f1d23f150cd4d080702acd3))
* check system requirements ([#162](https://github.com/rivet-gg/plugin-godot/issues/162)) ([3c378be](https://github.com/rivet-gg/plugin-godot/commit/3c378be8c720b38265b5342a3b3ad2f14bf04350))
* clarify onboarding text ([#137](https://github.com/rivet-gg/plugin-godot/issues/137)) ([e6ba0ef](https://github.com/rivet-gg/plugin-godot/commit/e6ba0efeef2c813edeaf8030ce895bc22360be08))
* run backend server from within the plugin ([#143](https://github.com/rivet-gg/plugin-godot/issues/143)) ([f2db914](https://github.com/rivet-gg/plugin-godot/commit/f2db91487f3ce19b6295af7fd7ea1af137c783af))
* run game server from within the plugin ([#139](https://github.com/rivet-gg/plugin-godot/issues/139)) ([f7bea53](https://github.com/rivet-gg/plugin-godot/commit/f7bea537173fd5a85277da61513b7ee07855867a))


### Bug Fixes

* bootstrap envs and backends ([#176](https://github.com/rivet-gg/plugin-godot/issues/176)) ([0a73685](https://github.com/rivet-gg/plugin-godot/commit/0a73685ac5f15b54948b3eac19e992c6d65d7fd2))
* handle thread exit cleanly ([#158](https://github.com/rivet-gg/plugin-godot/issues/158)) ([37f3896](https://github.com/rivet-gg/plugin-godot/commit/37f38963f99ad793669c21479f196bdd63aa0376))


### Code Refactoring

* clean up file tree ([#153](https://github.com/rivet-gg/plugin-godot/issues/153)) ([b027315](https://github.com/rivet-gg/plugin-godot/commit/b027315f00bdcdeec738f2786ee933c6cc9fc4e9))
* move sidekick to gdext ([#149](https://github.com/rivet-gg/plugin-godot/issues/149)) ([9d071d6](https://github.com/rivet-gg/plugin-godot/commit/9d071d652a8d608c660af14095909487e6fef192))
* rename playtest -&gt; develop ([#140](https://github.com/rivet-gg/plugin-godot/issues/140)) ([e772049](https://github.com/rivet-gg/plugin-godot/commit/e7720498256722362b33d0dd4557cbe13dbeb793))
* replace raw api call with toolchain calls ([#164](https://github.com/rivet-gg/plugin-godot/issues/164)) ([449d8ff](https://github.com/rivet-gg/plugin-godot/commit/449d8ff9efc223324f0f352d1452140a324aed15))


### Continuous Integration

* add gdext to ci ([#166](https://github.com/rivet-gg/plugin-godot/issues/166)) ([e4cbe40](https://github.com/rivet-gg/plugin-godot/commit/e4cbe40d1913a7bc56804b7db26509874be24023))
* fix release assets dirs ([#169](https://github.com/rivet-gg/plugin-godot/issues/169)) ([4dd831b](https://github.com/rivet-gg/plugin-godot/commit/4dd831b9fb3cdba29fe664a7d22d3466c987ca2d))


### Chores

* add ffi and cli binaries ([#175](https://github.com/rivet-gg/plugin-godot/issues/175)) ([f0ba721](https://github.com/rivet-gg/plugin-godot/commit/f0ba7216b032ec897ad50ef41566aba1164d83c2))
* add icons ([#155](https://github.com/rivet-gg/plugin-godot/issues/155)) ([0e4cb4d](https://github.com/rivet-gg/plugin-godot/commit/0e4cb4d8f73aa565f2f9836d34aebd484883f8fc))
* auto-restart backend daemon ([#152](https://github.com/rivet-gg/plugin-godot/issues/152)) ([b359466](https://github.com/rivet-gg/plugin-godot/commit/b359466ff34d66cb2156a1269eebc086086b8ddc))
* auto-start backend ([#151](https://github.com/rivet-gg/plugin-godot/issues/151)) ([64f9868](https://github.com/rivet-gg/plugin-godot/commit/64f9868a2fb4548acddafd58099b9a046fb1e99d))
* collect remaining logs on task exit ([#160](https://github.com/rivet-gg/plugin-godot/issues/160)) ([9c64970](https://github.com/rivet-gg/plugin-godot/commit/9c6497066238e90c45f224bef68f5fe01f802bae))
* impl extended backend configs ([#163](https://github.com/rivet-gg/plugin-godot/issues/163)) ([d96fe3d](https://github.com/rivet-gg/plugin-godot/commit/d96fe3d08c738a01edb8f60da1093500f522c9ab))
* migrate from ghcr to docker hub ([#165](https://github.com/rivet-gg/plugin-godot/issues/165)) ([c67f6b1](https://github.com/rivet-gg/plugin-godot/commit/c67f6b182634623ca34bed511be14ef4b91044d0))
* move examples to separate sub-projects ([#146](https://github.com/rivet-gg/plugin-godot/issues/146)) ([aa0da3e](https://github.com/rivet-gg/plugin-godot/commit/aa0da3e9788ca267492a04fc4dc995fc2b026a7d))
* move github links to settings ([#159](https://github.com/rivet-gg/plugin-godot/issues/159)) ([5d03207](https://github.com/rivet-gg/plugin-godot/commit/5d032074a64c2385e5556e5e0c11aca49eed8f45))
* move json ser/de to main thread ([#156](https://github.com/rivet-gg/plugin-godot/issues/156)) ([4e6dd67](https://github.com/rivet-gg/plugin-godot/commit/4e6dd67d3c2ea7abaadaa8840415373ae7df436e))
* move start/stop for gs and backend back in to main dock ([#150](https://github.com/rivet-gg/plugin-godot/issues/150)) ([cb10156](https://github.com/rivet-gg/plugin-godot/commit/cb101566cf26a3f0709ca0db5bd2bfebbd46b824))
* release 2.0.0-rc.1 ([eb5e076](https://github.com/rivet-gg/plugin-godot/commit/eb5e07646a793e193489ce50576400130593ff15))
* remove godot project from root in favor of examples ([#148](https://github.com/rivet-gg/plugin-godot/issues/148)) ([1fd8774](https://github.com/rivet-gg/plugin-godot/commit/1fd87740d21db5d6b49ba9bbff5421f3676816ff))
* remove rivet_api_endpoint ([#168](https://github.com/rivet-gg/plugin-godot/issues/168)) ([20b96a0](https://github.com/rivet-gg/plugin-godot/commit/20b96a09cb0dc42a1b2711ccf4fb2610456678e2))
* rename hub -&gt; dashboard ([#138](https://github.com/rivet-gg/plugin-godot/issues/138)) ([d42e808](https://github.com/rivet-gg/plugin-godot/commit/d42e8084eb4332566b4908e2f0006bc6587f7ac2))
* speed up loading spinner ([#142](https://github.com/rivet-gg/plugin-godot/issues/142)) ([6e65f0e](https://github.com/rivet-gg/plugin-godot/commit/6e65f0ed0337d2869e1bc73775d90439a6b8d784))
* style panel cleaner ([#157](https://github.com/rivet-gg/plugin-godot/issues/157)) ([b2e44be](https://github.com/rivet-gg/plugin-godot/commit/b2e44be6798574ebf09385861931664afa491ea1))
* update env selection logic ([#161](https://github.com/rivet-gg/plugin-godot/issues/161)) ([e88f17b](https://github.com/rivet-gg/plugin-godot/commit/e88f17ba30cd427c57fcd8752b8ec73eb8924699))

## [1.4.0](https://github.com/rivet-gg/plugin-godot/compare/v1.3.7...v1.4.0) (2024-07-02)


### Chores

* release 1.4.0 ([17110e7](https://github.com/rivet-gg/plugin-godot/commit/17110e72d2059f00eebc1c1fb32006b60a84569d))
* remove deprecated code ([#134](https://github.com/rivet-gg/plugin-godot/issues/134)) ([10fa97f](https://github.com/rivet-gg/plugin-godot/commit/10fa97f9270cc7c8fd09e5f7d964275dc66fda91))

## [1.3.7](https://github.com/rivet-gg/plugin-godot/compare/v1.3.6...v1.3.7) (2024-06-27)


### Bug Fixes

* save scenes before deploy ([#131](https://github.com/rivet-gg/plugin-godot/issues/131)) ([d4ce4fb](https://github.com/rivet-gg/plugin-godot/commit/d4ce4fb601f69bf6cd037e3f0ccbef703698c783))

## [1.3.6](https://github.com/rivet-gg/plugin-godot/compare/v1.3.5...v1.3.6) (2024-06-22)


### Chores

* update asset listing ([#124](https://github.com/rivet-gg/plugin-godot/issues/124)) ([7d45f67](https://github.com/rivet-gg/plugin-godot/commit/7d45f67600f1b22db449a0aaa25ba088ec591854))

## [1.3.5](https://github.com/rivet-gg/plugin-godot/compare/v1.3.4...v1.3.5) (2024-06-21)


### Bug Fixes

* setClosed endpoint ([#122](https://github.com/rivet-gg/plugin-godot/issues/122)) ([947a33c](https://github.com/rivet-gg/plugin-godot/commit/947a33c016f03539a848bdbb7f56be967f25624a))

## [1.3.4](https://github.com/rivet-gg/plugin-godot/compare/v1.3.3...v1.3.4) (2024-06-10)


### Bug Fixes

* replace usage of the RivetPluginBridge identifier ([c07f2a1](https://github.com/rivet-gg/plugin-godot/commit/c07f2a12a8c06b2ddc2f2c9bce50b962c34034c0))


### Chores

* bump cli version ([#119](https://github.com/rivet-gg/plugin-godot/issues/119)) ([6f841d0](https://github.com/rivet-gg/plugin-godot/commit/6f841d017f38ff0e7e94601f6f7edc78ec5cf6f8))

## [1.3.3](https://github.com/rivet-gg/plugin-godot/compare/v1.3.2...v1.3.3) (2024-06-06)


### Bug Fixes

* update plugin name ([#114](https://github.com/rivet-gg/plugin-godot/issues/114)) ([962023a](https://github.com/rivet-gg/plugin-godot/commit/962023afb73c5f83e332665c9bdf1cef9694fb0e))


### Continuous Integration

* prevent duplicate plugin image uploads ([#115](https://github.com/rivet-gg/plugin-godot/issues/115)) ([fae9672](https://github.com/rivet-gg/plugin-godot/commit/fae9672e73de415502acad189ef73efdde72ea10))

## [1.3.2](https://github.com/rivet-gg/plugin-godot/compare/v1.3.1...v1.3.2) (2024-05-31)


### Bug Fixes

* empty namespaces on plugin launch ([#112](https://github.com/rivet-gg/plugin-godot/issues/112)) ([8c457ab](https://github.com/rivet-gg/plugin-godot/commit/8c457ab9507f09206291a3661b9142b9101ecf91))
* fix runtime dependency graph ([#111](https://github.com/rivet-gg/plugin-godot/issues/111)) ([308eeaf](https://github.com/rivet-gg/plugin-godot/commit/308eeafb1f0fbcc85a55a8815eb148347c88332b))

## [1.3.1](https://github.com/rivet-gg/plugin-godot/compare/v1.3.0...v1.3.1) (2024-05-29)


### Bug Fixes

* cfg file comments ([#109](https://github.com/rivet-gg/plugin-godot/issues/109)) ([d8082b3](https://github.com/rivet-gg/plugin-godot/commit/d8082b3808196dbf886af56bb6ed3b002171f2b3))

## [1.3.0](https://github.com/rivet-gg/plugin-godot/compare/v1.2.1...v1.3.0) (2024-05-29)


### Features

* logs and lobbies link buttons ([#100](https://github.com/rivet-gg/plugin-godot/issues/100)) ([4bd9442](https://github.com/rivet-gg/plugin-godot/commit/4bd9442e33624d422f0adc8d0dfbefbce81899ab))


### Bug Fixes

* change default namespace values ([#99](https://github.com/rivet-gg/plugin-godot/issues/99)) ([d0bf2bd](https://github.com/rivet-gg/plugin-godot/commit/d0bf2bd60170e69689ca170b3404b9aa1de064ef))
* update namespaces after deploying ([#102](https://github.com/rivet-gg/plugin-godot/issues/102)) ([4f9707d](https://github.com/rivet-gg/plugin-godot/commit/4f9707dace75f5db3185a4c61a70c05316e92227))


### Continuous Integration

* update plugin version after release ([#103](https://github.com/rivet-gg/plugin-godot/issues/103)) ([9b15332](https://github.com/rivet-gg/plugin-godot/commit/9b15332a2a7dd4dc0bc7461e5c9a4a671b4e92f0))


### Chores

* bump CLI version ([#108](https://github.com/rivet-gg/plugin-godot/issues/108)) ([5262763](https://github.com/rivet-gg/plugin-godot/commit/5262763eb7f2e1935d66de121a1bfff27ae2f75b))

## [1.2.1](https://github.com/rivet-gg/plugin-godot/compare/v1.2.0...v1.2.1) (2024-05-16)


### Bug Fixes

* fix deploy tab code indentation ([#85](https://github.com/rivet-gg/plugin-godot/issues/85)) ([221472a](https://github.com/rivet-gg/plugin-godot/commit/221472ad692f12f871092edc3aff380551a69a90))

## [1.2.0](https://github.com/rivet-gg/plugin-godot/compare/v1.1.4...v1.2.0) (2024-05-15)


### Features

* Ask user if they want to save before build and deploy ([14e30c8](https://github.com/rivet-gg/plugin-godot/commit/14e30c81b8b477320f1716db013c4572e84688b1))
* Improve loading screen ([bf1a960](https://github.com/rivet-gg/plugin-godot/commit/bf1a960a7cebcee376bb049f0c5b51966631ea32))


### Bug Fixes

* Save scripts as well on check ([44bc1e9](https://github.com/rivet-gg/plugin-godot/commit/44bc1e97dcff12eaadf23f84da1edca2c44d60a9))

## [1.1.4](https://github.com/rivet-gg/plugin-godot/compare/v1.1.3...v1.1.4) (2024-03-11)


### Bug Fixes

* Fix Windows installer for Rivet CLI ([#70](https://github.com/rivet-gg/plugin-godot/issues/70)) ([e08222e](https://github.com/rivet-gg/plugin-godot/commit/e08222e6bc544d6f4d034c178b8198f2acdb6ee0))

## [1.1.3](https://github.com/rivet-gg/plugin-godot/compare/v1.1.2...v1.1.3) (2024-03-08)


### Bug Fixes

* Fix icon url ([3a81613](https://github.com/rivet-gg/plugin-godot/commit/3a816138359bf22f544b86c437fb22ef38f58319))

## [1.1.2](https://github.com/rivet-gg/plugin-godot/compare/v1.1.1...v1.1.2) (2024-03-08)


### Bug Fixes

* Run deploy workflow in release please workflow ([e0dba08](https://github.com/rivet-gg/plugin-godot/commit/e0dba08a00e5277dc8a37cf68f9bdf378eae905e))

## [1.1.1](https://github.com/rivet-gg/plugin-godot/compare/v1.1.0...v1.1.1) (2024-03-08)


### Bug Fixes

* Release to trigger CI to asset store ([465e36c](https://github.com/rivet-gg/plugin-godot/commit/465e36cf8586011f9cf89a39f0f9dfb3b8552410))

## [1.1.0](https://github.com/rivet-gg/plugin-godot/compare/v1.0.0...v1.1.0) (2024-03-08)


### Features

* CI Push to Godot Asset Store ([#57](https://github.com/rivet-gg/plugin-godot/issues/57)) ([fe226cd](https://github.com/rivet-gg/plugin-godot/commit/fe226cdd030ae05edecfacc7237389b8ca6d15a3))

## [1.0.0](https://github.com/rivet-gg/plugin-godot/compare/v1.0.0-rc.1...v1.0.0) (2024-02-22)


### Features

* Add Release Please ([#52](https://github.com/rivet-gg/plugin-godot/issues/52)) ([21ac491](https://github.com/rivet-gg/plugin-godot/commit/21ac4915ec3a4cd48b14fa97aa621369328686e6))
* format RivetPluginBridge ([#27](https://github.com/rivet-gg/plugin-godot/issues/27)) ([7c0f146](https://github.com/rivet-gg/plugin-godot/commit/7c0f14625daa4e07cf90d92c947f84eb645c4b5a))
* **GDT-72:** Add "debug" setting to turn on plugin logs ([#26](https://github.com/rivet-gg/plugin-godot/issues/26)) ([aec8b1d](https://github.com/rivet-gg/plugin-godot/commit/aec8b1d4d93969d8d2cd692ae13f66f260582f67))


### Miscellaneous Chores

* release 1.0.0 ([#53](https://github.com/rivet-gg/plugin-godot/issues/53)) ([0d269fe](https://github.com/rivet-gg/plugin-godot/commit/0d269fef541c81aebad05cc56869f3a8068e273b))
