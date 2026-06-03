-- Fix: include slug in insert_and_shift_unit to satisfy NOT NULL constraint
CREATE OR REPLACE FUNCTION insert_and_shift_unit(
    p_track_id UUID,
    p_title_bn TEXT,
    p_title_ar TEXT,
    p_tier_level INT,
    p_slug TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    new_unit_id UUID;
    target_sequence INT;
    effective_slug TEXT;
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

    -- Generate a fallback slug if caller didn't provide one
    effective_slug := COALESCE(p_slug, 'unit-' || extract(epoch from now())::bigint::text);

    -- Insert the new unit into the cleared slot (slug now always set)
    INSERT INTO units (track_id, title_bn, title_ar, tier_level, sequence_order, sort_order, status, slug)
    VALUES (p_track_id, p_title_bn, p_title_ar, p_tier_level, target_sequence, target_sequence, 'draft', effective_slug)
    RETURNING id INTO new_unit_id;

    RETURN new_unit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
