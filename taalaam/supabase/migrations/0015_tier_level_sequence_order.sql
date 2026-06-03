-- Add tier_level and sequence_order to units for automated router pipeline
ALTER TABLE units ADD COLUMN IF NOT EXISTS tier_level INT DEFAULT 1;
ALTER TABLE units ADD COLUMN IF NOT EXISTS sequence_order INT DEFAULT 1;

-- Seed sequence_order from existing sort_order so current ordering is preserved
UPDATE units SET sequence_order = sort_order;

-- Smart insertion function: slots a new unit at the right tier position
-- and shifts all higher-sequence units forward by 1 in both sort_order and sequence_order.
CREATE OR REPLACE FUNCTION insert_and_shift_unit(
    p_track_id UUID,
    p_title_bn TEXT,
    p_title_ar TEXT,
    p_tier_level INT
) RETURNS UUID AS $$
DECLARE
    new_unit_id UUID;
    target_sequence INT;
BEGIN
    -- Find the next open slot after the last unit at this tier or lower
    SELECT COALESCE(MAX(sequence_order), 0) + 1
    INTO target_sequence
    FROM units
    WHERE track_id = p_track_id AND tier_level <= p_tier_level;

    -- Push every unit at or beyond the target slot forward by 1
    UPDATE units
    SET sequence_order = sequence_order + 1,
        sort_order     = sort_order + 1
    WHERE track_id = p_track_id AND sequence_order >= target_sequence;

    -- Insert the new unit into the cleared slot
    INSERT INTO units (track_id, title_bn, title_ar, tier_level, sequence_order, sort_order, status)
    VALUES (p_track_id, p_title_bn, p_title_ar, p_tier_level, target_sequence, target_sequence, 'draft')
    RETURNING id INTO new_unit_id;

    RETURN new_unit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
