module movectf::potato {
    use sui::tx_context::{Self, TxContext};
    use movectf::counter::{Self, Counter};

    use sui::event;

    use std::vector;
    use sui::bcs;
    use std::hash;
    use sui::object;

    struct Potato {
        has_cut: bool,
        has_cook: bool,
    }

    fun init(ctx: &mut TxContext) {
        counter::create_counter(ctx);
    }

    fun seed(ctx: &mut TxContext): vector<u8> {
        let ctx_bytes = bcs::to_bytes(ctx);
        let uid = object::new(ctx);
        let uid_bytes: vector<u8> = object::uid_to_bytes(&uid);
        object::delete(uid);

        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, ctx_bytes);
        vector::append<u8>(&mut info, uid_bytes);

        let hash: vector<u8> = hash::sha3_256(info);
        hash
    }

    fun bytes_to_u64(bytes: vector<u8>): u64 {
        let value = 0u64;
        let i = 0u64;
        while (i < 8) {
            value = value | ((*vector::borrow(&bytes, i) as u64) << ((8 * (7 - i)) as u8));
            i = i + 1;
        };
        return value
    }

    public fun good_knife(source : vector<u8>, ctx: &mut TxContext): bool {
        let original_plaintext : vector<u8> = vector[
            48, 71, 61, 67, 127, 90, 92, 67, 37, 55, 55, 57, 45, 98, 81, 39, 102, 73, 122, 75, 
            97, 96, 65, 34, 75, 74, 121, 20, 113, 36, 83, 64, 26, 122, 93, 79, 119, 82, 27, 22, 
            33, 103, 91, 32, 56, 106, 105, 32, 108, 33, 23, 106, 13, 62, 60, 103, 19, 31, 115, 
            24, 98, 89, 75, 26, 93, 20, 17, 25, 127, 121, 61, 111, 98, 124, 86, 127, 118, 70, 
            74, 63, 93, 92, 85, 83, 80, 93, 62, 112, 38, 127, 58, 99, 19, 49, 113, 39, 17, 35, 
            117, 62, 17, 97, 19, 13, 92, 39, 76, 65, 37, 29, 59, 126, 52, 52, 82, 38, 48, 98, 
            107, 58, 25, 120, 112, 51, 76, 32, 13, 46];

        let sender_addr_bytes : vector<u8> = seed(ctx);

        let plaintext : vector<u8> = vector::empty<u8>();
        let i = 0;

        while( i < vector::length(&source) ) {
            let tmp1 : &u8 = vector::borrow(&source, i);
            let tmp2 : &u8 = vector::borrow(&sender_addr_bytes, (i % 32));
            vector::push_back(&mut plaintext, *tmp1 ^ *tmp2);
            i = i+1;
        };
        plaintext == original_plaintext
    }


    fun temperature(ctx: &mut TxContext): u64 {
        let value = bytes_to_u64(seed(ctx));
        value % 100
    }

    public fun get_potato(): Potato {
        Potato {
            has_cut: false,
            has_cook: false,
        } 
    }

    public fun cut_potatoes(cipher: vector<u8>, potato: &mut Potato,ctx: &mut TxContext) {
        assert!(!potato.has_cut, 0);
        if (good_knife(cipher, ctx)) {
            potato.has_cut = true;
        }else {
            let Potato {has_cut: _, has_cook: _ } = potato;
        };
    }

    public fun cook_potato(potato: &mut Potato, ctx: &mut TxContext) {
        assert!(!potato.has_cook && potato.has_cut, 0);
        if (temperature(ctx) == 90) {
            potato.has_cook = true;
        }else {
            let Potato {has_cut: _, has_cook: _ } = potato;
        };
    }


    struct Flag has copy, drop {
        user: address,
        flag: bool,
    }

    // eat_potato
    public fun get_flag(user_counter: &mut Counter, potato: Potato, ctx: &mut TxContext) {
        counter::increment(user_counter);
        counter::is_within_limit(user_counter);

        assert!(potato.has_cook && potato.has_cut, 0);
        let Potato {has_cut: _, has_cook: _ } = potato;

        event::emit (Flag {
            user: tx_context::sender(ctx),
            flag: true,
        });
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(ctx)
    }
}
