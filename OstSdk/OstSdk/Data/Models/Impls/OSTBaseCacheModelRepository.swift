//
//  OSTBaseCacheModelRepository.swift
//  OstSdk
//
//  Created by aniket ayachit on 13/12/18.
//  Copyright © 2018 aniket ayachit. All rights reserved.
//

import Foundation


class OSTBaseCacheModelRepository: OSTBaseModelRepository {
    
    private var inMemoryCache: [String: OSTBaseEntity] = [:]
    private var entityCache = NSCache<NSString, OSTBaseEntity>()
    
    override init() {
        super.init()
        entityCache.countLimit = maxCountToCache()
    }
    
    func maxCountToCache() -> Int {
        return 5
    }
    
    func isCacheEnable() -> Bool {
        return true
    }
    
    //MARK: - get
    override func get(_ id: String) throws -> OSTBaseEntity? {
        if let entity = getDataFromCache(id) {
            return entity
        }
        do {
           
            if let entity: OSTBaseEntity = try super.get(id) {
                saveDataInCache(key: entity.id, val: entity)
                return entity
            }
            return nil
        }catch let error {
            throw error
        }
        
    }
    
    override func bulkFetchDataForId(_ ids: Array<String>) -> [String: OSTBaseEntity?] {
        var idsToFetch: Array<String> = []
        var availableEntities: [String: OSTBaseEntity] = [:]
        for id in ids {
            if let entity = getDataFromCache(id) {
                availableEntities[id] = entity
            }else {
                idsToFetch.append(id)
            }
        }
        if (idsToFetch.count > 0) {
            var dbEntities = super.bulkFetchDataForId(idsToFetch)
            for (key, dbEntity) in dbEntities {
                if dbEntity != nil {
                    saveDataInCache(key: key, val: dbEntity!)
                }
            }
            for (key,val) in availableEntities {
                dbEntities[key] = val
            }
            return dbEntities
        }
            
       return availableEntities
    }
    
    //MARK: - save
    override func insertOrUpdate(_ entityObj: OSTBaseEntity) -> OSTBaseEntity? {
        if let cacheEntity = getDataFromCache(entityObj.id) {
            if (entityObj.uts as NSString).intValue > (cacheEntity.uts as NSString).intValue {
               return commonInsertOrUpdate(entityObj)
            }
            return cacheEntity
        }
        return commonInsertOrUpdate(entityObj)
    }
    
    func commonInsertOrUpdate(_ entityObj: OSTBaseEntity) -> OSTBaseEntity? {
        saveDataInMemory(key: entityObj.id, val: entityObj)
        saveDataInCache(key: entityObj.id, val: entityObj)
        if let dbEntityObj = super.insertOrUpdate(entityObj) {
            removeInMemoryData(key: entityObj.id)
            return dbEntityObj
        }
        return nil
    }
    
    override func bulkInsertOrUpdate(_ entityArray: Array<OSTBaseEntity>) -> (Array<OSTBaseEntity>?, Array<OSTBaseEntity>?) {
        var entitiesToSave: Array<OSTBaseEntity> = []
        var entitiesToReturn: Array<OSTBaseEntity> = []
        for entity in entityArray {
            if let cacheEntity = getDataFromCache(entity.id) {
                if (entity.uts as NSString).intValue > (cacheEntity.uts as NSString).intValue {
                    entitiesToSave.append(entity)
                }else {
                    entitiesToReturn.append(entity)
                }
            }else {
                entitiesToSave.append(entity)
            }
        }
        
        if (entitiesToSave.count > 0) {
            bulkSaveDataInMemory(entitiesToSave)
            let (successArray, failuarArray) = super.bulkInsertOrUpdate(entitiesToSave)
            if (successArray != nil){
                for dbEntity in (successArray!) {
                    removeInMemoryData(key: dbEntity.id)
                }
            }
            
            return (entitiesToReturn + (successArray ?? []) , failuarArray ?? nil)
        }
        
        return (entitiesToReturn, nil)
    }

    //MARK: - delete
    override func delete(_ id: String, success: ((Bool)->Void)?) {
        if (!id.isAlphanumeric) {success?(false)}
        super.delete(id, success: { (isSuccess) in
            self.removeFromCache(key: id)
            self.removeInMemoryData(key: id)
            success?(isSuccess)
        })
    }
    
    //MARK: - Cache Functions
    fileprivate func getDataFromCache(_ id: String) -> OSTBaseEntity? {
        if (isCacheEnable()) {
            if let cacheData = entityCache.object(forKey: id as NSString) {
                return cacheData
            }
        }
        if let inMemoryData = inMemoryCache[id] {
            return inMemoryData
        }
        return nil
    }
    
    fileprivate func saveDataInMemory(key: String, val: OSTBaseEntity) {
        inMemoryCache[key] = val
    }
    
    fileprivate func bulkSaveDataInMemory(_ entities: Array<OSTBaseEntity>) {
        for entity in entities {
            saveDataInMemory(key: entity.id, val:entity)
            saveDataInCache(key: entity.id, val: entity)
        }
    }
    
    fileprivate func removeInMemoryData(key: String) {
        inMemoryCache[key] = nil
    }
    
    func saveDataInCache(key: String, val: OSTBaseEntity) {
        if (isCacheEnable()) {
            entityCache.setObject(val, forKey: key as NSString)
        }
    }

    func removeFromCache(key: String) {
        if (isCacheEnable()) {
            entityCache.removeObject(forKey: key as NSString)
        }
    }
    
    fileprivate func bulkRemoveFromCache(keys: Array<String>) {
        for key in keys {
            removeFromCache(key: key)
        }
    }
}
