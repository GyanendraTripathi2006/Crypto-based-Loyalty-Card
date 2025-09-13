module MyModule::LoyaltyCard {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a user's loyalty card with points and tier status.
    struct LoyaltyCard has store, key {
        points: u64,           // Total loyalty points earned
        tier: u8,              // Loyalty tier (1=Bronze, 2=Silver, 3=Gold)
        total_spent: u64,      // Total amount spent by the user
    }

    /// Error codes
    const E_INSUFFICIENT_POINTS: u64 = 1;
    const E_INVALID_AMOUNT: u64 = 2;

    /// Function to initialize a new loyalty card for a user.
    public fun create_loyalty_card(user: &signer) {
        let loyalty_card = LoyaltyCard {
            points: 0,
            tier: 1,           // Start with Bronze tier
            total_spent: 0,
        };
        move_to(user, loyalty_card);
    }

    /// Function to earn points by making a purchase and optionally redeem points for rewards.
    public fun earn_and_redeem_points(
        user: &signer, 
        merchant: address, 
        purchase_amount: u64,
        points_to_redeem: u64
    ) acquires LoyaltyCard {
        assert!(purchase_amount > 0, E_INVALID_AMOUNT);
        
        let user_addr = signer::address_of(user);
        let loyalty_card = borrow_global_mut<LoyaltyCard>(user_addr);
        
        // Check if user has enough points to redeem
        assert!(loyalty_card.points >= points_to_redeem, E_INSUFFICIENT_POINTS);
        
        // Calculate discount (1 point = 0.01 AptosCoin discount)
        let discount = points_to_redeem;
        let final_amount = purchase_amount - discount;
        
        // Transfer payment to merchant
        let payment = coin::withdraw<AptosCoin>(user, final_amount);
        coin::deposit<AptosCoin>(merchant, payment);
        
        // Update loyalty card: earn 1 point per AptosCoin spent, redeem used points
        let earned_points = final_amount / 100; // 1 point per 1 AptosCoin
        loyalty_card.points = loyalty_card.points + earned_points - points_to_redeem;
        loyalty_card.total_spent = loyalty_card.total_spent + final_amount;
        
        // Update tier based on total spending
        if (loyalty_card.total_spent >= 10000) {
            loyalty_card.tier = 3; // Gold
        } else if (loyalty_card.total_spent >= 5000) {
            loyalty_card.tier = 2; // Silver
        };
    }
}