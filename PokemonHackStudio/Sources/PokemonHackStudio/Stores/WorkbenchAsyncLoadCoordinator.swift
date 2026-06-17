import Foundation

struct WorkbenchAsyncLoadToken: Equatable {
    let projectID: String
    let rootPath: String
    let generation: Int

    init(project: IndexedProjectSummary, generation: Int) {
        projectID = project.id
        rootPath = project.rootPath
        self.generation = generation
    }

    func accepts(currentProjectID: String?, currentGeneration: Int) -> Bool {
        currentProjectID == projectID && currentGeneration == generation
    }
}
