modules = {}
@provide ?= (name, module) -> modules[name] = module
@require ?= (name) -> modules[name] ? @[name]