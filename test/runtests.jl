using Test
using LevelDB

run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
run(`rm -rf level.db.3`)

@testset "DB basic operations" begin
    @test_throws ErrorException LevelDB.DB("level.db")

    db = LevelDB.DB("level.db", create_if_missing = true)
    close(db)
    @test !isopen(db)

    @test_throws ErrorException LevelDB.DB("level.db", error_if_exists = true)
    db = LevelDB.DB("level.db")

    db[[0x00]] = [0x01]
    @test db[[0x00]] == [0x01]
    delete!(db, [0x00])
    # as in Dict, deleting a non-existing key should not throw an error
    delete!(db, [0x00])
    @test_throws KeyError db[[0x00]]
    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL
end

@testset "DB batching and iteration" begin
    db = LevelDB.DB("level.db.2", create_if_missing = true)
    d = Dict([0xa] => [0x1],
             [0xb] => [0x2],
             [0xc] => [0x3],
             [0xd] => [0x4],)

    db[keys(d)] = values(d)

    @test db[[0xa]] == [0x1]
    @test db[[0xb]] == [0x2]
    @test db[[0xc]] == [0x3]
    @test db[[0xd]] == [0x4]

    function size_of(db)
        i = 0
        for (k, v) in db
            i += 1
        end
        i
    end
    @test size_of(db) == 4
    for (k, v) in db
        delete!(db, k)
    end
    @test size_of(db) == 0

    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL

    # nothing should happen here
    close(db)
    @test db.handle        == C_NULL
    @test db.options       == C_NULL
    @test db.write_options == C_NULL
    @test db.read_options  == C_NULL
end



@testset "DB Errors" begin
    @test_throws ErrorException LevelDB.DB("level.db.3")
end

run(`rm -rf level.db`)
run(`rm -rf level.db.2`)
run(`rm -rf level.db.3`)
