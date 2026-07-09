SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: scotland; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA scotland;


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: address_base; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.address_base (
    uprn character varying NOT NULL,
    address_line1 character varying,
    address_line2 character varying,
    address_line3 character varying,
    address_line4 character varying,
    address_type character varying(15),
    classification_code character varying(6),
    country_code character varying(1),
    postcode character varying,
    town character varying
);


--
-- Name: address_base_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.address_base_versions (
    version_number integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    version_name character varying NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: assessment_search_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_search_address (
    assessment_id character varying NOT NULL,
    address text
);


--
-- Name: assessment_statistics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_statistics (
    id bigint NOT NULL,
    assessment_type character varying NOT NULL,
    assessments_count integer NOT NULL,
    country character varying,
    day_date timestamp without time zone NOT NULL,
    rating_average double precision,
    transaction_type integer
);


--
-- Name: assessment_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessment_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessment_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessment_statistics_id_seq OWNED BY public.assessment_statistics.id;


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments (
    assessment_id character varying NOT NULL,
    address_id character varying,
    address_line1 character varying,
    address_line2 character varying,
    address_line3 character varying,
    address_line4 character varying,
    cancelled_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    current_energy_efficiency_rating integer DEFAULT 1 NOT NULL,
    date_of_assessment timestamp without time zone,
    date_of_expiry timestamp without time zone NOT NULL,
    date_registered timestamp without time zone,
    hashed_assessment_id character varying,
    migrated boolean DEFAULT false,
    not_for_issue_at timestamp without time zone,
    opt_out boolean DEFAULT false,
    postcode character varying,
    scheme_assessor_id character varying NOT NULL,
    town character varying,
    type_of_assessment character varying
);


--
-- Name: assessments_address_id; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments_address_id (
    assessment_id character varying NOT NULL,
    address_id character varying,
    address_updated_at timestamp(6) without time zone,
    matched_confidence double precision,
    matched_uprn character varying(20),
    source character varying
);


--
-- Name: assessments_country_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments_country_ids (
    assessment_id character varying NOT NULL,
    country_id integer
);


--
-- Name: assessments_xml; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments_xml (
    assessment_id character varying DEFAULT ''::character varying NOT NULL,
    schema_type character varying,
    xml xml
);


--
-- Name: assessors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessors (
    scheme_assessor_id character varying NOT NULL,
    address_line1 character varying,
    address_line2 character varying,
    address_line3 character varying,
    also_known_as character varying,
    company_address_line1 character varying,
    company_address_line2 character varying,
    company_address_line3 character varying,
    company_email character varying,
    company_name character varying,
    company_postcode character varying,
    company_reg_no character varying,
    company_telephone_number character varying,
    company_town character varying,
    company_website character varying,
    date_of_birth timestamp without time zone NOT NULL,
    domestic_rd_sap_qualification character varying,
    domestic_sap_qualification character varying,
    email character varying,
    first_name character varying NOT NULL,
    gda_qualification character varying,
    last_name character varying NOT NULL,
    middle_names character varying,
    non_domestic_cc4_qualification character varying,
    non_domestic_dec_qualification character varying,
    non_domestic_nos3_qualification character varying,
    non_domestic_nos4_qualification character varying,
    non_domestic_nos5_qualification character varying,
    non_domestic_sp3_qualification character varying,
    postcode character varying,
    registered_by smallint NOT NULL,
    scotland_dec_and_ar_qualification character varying,
    scotland_nondomestic_existing_building_qualification character varying,
    scotland_nondomestic_new_building_qualification character varying,
    scotland_rdsap_qualification character varying,
    scotland_sap_existing_building_qualification character varying,
    scotland_sap_new_building_qualification character varying,
    scotland_section63_qualification character varying,
    search_results_comparison_postcode character varying,
    telephone_number character varying,
    town character varying
);


--
-- Name: assessors_status_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessors_status_events (
    id bigint NOT NULL,
    assessor jsonb DEFAULT '{}'::jsonb,
    auth_client_id character varying,
    new_status character varying,
    previous_status character varying,
    qualification_type character varying,
    recorded_at timestamp without time zone,
    scheme_assessor_id character varying
);


--
-- Name: assessors_status_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assessors_status_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assessors_status_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assessors_status_events_id_seq OWNED BY public.assessors_status_events.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    data jsonb,
    entity_id character varying NOT NULL,
    entity_type character varying NOT NULL,
    event_type character varying NOT NULL,
    "timestamp" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    country_id bigint NOT NULL,
    address_base_country_code jsonb DEFAULT '"{}"'::jsonb,
    country_code character varying,
    country_name character varying
);


--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.countries_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.countries_country_id_seq OWNED BY public.countries.country_id;


--
-- Name: green_deal_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.green_deal_assessments (
    assessment_id character varying NOT NULL,
    green_deal_plan_id character varying NOT NULL
);


--
-- Name: green_deal_fuel_code_map; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.green_deal_fuel_code_map (
    id bigint NOT NULL,
    fuel_category integer,
    fuel_code integer,
    fuel_heat_source integer
);


--
-- Name: green_deal_fuel_code_map_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.green_deal_fuel_code_map_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: green_deal_fuel_code_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.green_deal_fuel_code_map_id_seq OWNED BY public.green_deal_fuel_code_map.id;


--
-- Name: green_deal_fuel_price_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.green_deal_fuel_price_data (
    id bigint NOT NULL,
    fuel_heat_source integer,
    fuel_price numeric(10,2),
    standing_charge numeric(5,2)
);


--
-- Name: green_deal_fuel_price_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.green_deal_fuel_price_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: green_deal_fuel_price_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.green_deal_fuel_price_data_id_seq OWNED BY public.green_deal_fuel_price_data.id;


--
-- Name: green_deal_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.green_deal_plans (
    green_deal_plan_id character varying NOT NULL,
    cca_regulated boolean,
    charge_uplift_amount numeric,
    charge_uplift_date timestamp without time zone,
    charges jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    end_date timestamp without time zone,
    fixed_interest_rate boolean,
    interest_rate numeric,
    measures jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    measures_removed boolean,
    provider_email character varying,
    provider_name character varying,
    provider_telephone character varying,
    savings jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    start_date timestamp without time zone,
    structure_changed boolean
);


--
-- Name: linked_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.linked_assessments (
    assessment_id character varying NOT NULL,
    linked_assessment_id character varying NOT NULL
);


--
-- Name: open_data_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.open_data_logs (
    id bigint NOT NULL,
    assessment_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    report_type character varying,
    task_id integer NOT NULL
);


--
-- Name: open_data_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.open_data_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_data_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.open_data_logs_id_seq OWNED BY public.open_data_logs.id;


--
-- Name: overridden_lodgement_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.overridden_lodgement_events (
    id bigint NOT NULL,
    assessment_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    rule_triggers jsonb DEFAULT '[]'::jsonb
);


--
-- Name: overridden_lodgement_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.overridden_lodgement_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: overridden_lodgement_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.overridden_lodgement_events_id_seq OWNED BY public.overridden_lodgement_events.id;


--
-- Name: postcode_geolocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postcode_geolocation (
    postcode character varying NOT NULL,
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    region character varying NOT NULL
);


--
-- Name: postcode_outcode_geolocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postcode_outcode_geolocations (
    outcode character varying NOT NULL,
    latitude numeric NOT NULL,
    longitude numeric NOT NULL,
    region character varying NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: schemes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schemes (
    scheme_id bigint NOT NULL,
    active boolean DEFAULT true,
    active_eng_wls_nir boolean DEFAULT false,
    active_scotland boolean DEFAULT false,
    name character varying
);


--
-- Name: schemes_scheme_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schemes_scheme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schemes_scheme_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schemes_scheme_id_seq OWNED BY public.schemes.scheme_id;


--
-- Name: assessment_search_address; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.assessment_search_address (
    assessment_id character varying NOT NULL,
    address text
);


--
-- Name: assessments; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.assessments (
    assessment_id character varying NOT NULL,
    address_id character varying,
    address_line1 character varying,
    address_line2 character varying,
    address_line3 character varying,
    address_line4 character varying,
    cancelled_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    current_energy_efficiency_rating integer DEFAULT 1 NOT NULL,
    date_of_assessment timestamp without time zone,
    date_of_expiry timestamp without time zone NOT NULL,
    date_registered timestamp without time zone,
    hashed_assessment_id character varying,
    migrated boolean DEFAULT false,
    not_for_issue_at timestamp without time zone,
    opt_out boolean DEFAULT false,
    postcode character varying,
    scheme_assessor_id character varying NOT NULL,
    town character varying,
    type_of_assessment character varying
);


--
-- Name: assessments_address_id; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.assessments_address_id (
    assessment_id character varying NOT NULL,
    address_id character varying,
    address_updated_at timestamp(6) without time zone,
    matched_confidence double precision,
    matched_uprn character varying(20),
    source character varying
);


--
-- Name: assessments_country_ids; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.assessments_country_ids (
    assessment_id character varying NOT NULL,
    country_id integer
);


--
-- Name: assessments_xml; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.assessments_xml (
    assessment_id character varying DEFAULT ''::character varying NOT NULL,
    schema_type character varying,
    xml xml
);


--
-- Name: green_deal_assessments; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.green_deal_assessments (
    assessment_id character varying NOT NULL,
    green_deal_plan_id character varying NOT NULL
);


--
-- Name: green_deal_plans; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.green_deal_plans (
    cca_regulated boolean,
    charge_uplift_amount numeric,
    charge_uplift_date timestamp(6) without time zone,
    charges jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    end_date timestamp(6) without time zone,
    fixed_interest_rate boolean,
    green_deal_plan_id character varying,
    interest_rate numeric,
    measures jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    measures_removed boolean,
    provider_email character varying,
    provider_name character varying,
    provider_telephone character varying,
    savings jsonb DEFAULT '"[]"'::jsonb NOT NULL,
    start_date timestamp(6) without time zone,
    structure_changed boolean
);


--
-- Name: linked_assessments; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.linked_assessments (
    assessment_id character varying NOT NULL,
    linked_assessment_id character varying NOT NULL
);


--
-- Name: overridden_lodgement_events; Type: TABLE; Schema: scotland; Owner: -
--

CREATE TABLE scotland.overridden_lodgement_events (
    id bigint DEFAULT nextval('public.overridden_lodgement_events_id_seq'::regclass) NOT NULL,
    assessment_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    rule_triggers jsonb DEFAULT '[]'::jsonb
);


--
-- Name: assessment_statistics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_statistics ALTER COLUMN id SET DEFAULT nextval('public.assessment_statistics_id_seq'::regclass);


--
-- Name: assessors_status_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessors_status_events ALTER COLUMN id SET DEFAULT nextval('public.assessors_status_events_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: countries country_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries ALTER COLUMN country_id SET DEFAULT nextval('public.countries_country_id_seq'::regclass);


--
-- Name: green_deal_fuel_code_map id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_fuel_code_map ALTER COLUMN id SET DEFAULT nextval('public.green_deal_fuel_code_map_id_seq'::regclass);


--
-- Name: green_deal_fuel_price_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_fuel_price_data ALTER COLUMN id SET DEFAULT nextval('public.green_deal_fuel_price_data_id_seq'::regclass);


--
-- Name: open_data_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_data_logs ALTER COLUMN id SET DEFAULT nextval('public.open_data_logs_id_seq'::regclass);


--
-- Name: overridden_lodgement_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.overridden_lodgement_events ALTER COLUMN id SET DEFAULT nextval('public.overridden_lodgement_events_id_seq'::regclass);


--
-- Name: schemes scheme_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schemes ALTER COLUMN scheme_id SET DEFAULT nextval('public.schemes_scheme_id_seq'::regclass);


--
-- Name: address_base address_base_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address_base
    ADD CONSTRAINT address_base_pkey PRIMARY KEY (uprn);


--
-- Name: address_base_versions address_base_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address_base_versions
    ADD CONSTRAINT address_base_versions_pkey PRIMARY KEY (version_number);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assessment_search_address assessment_search_address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_search_address
    ADD CONSTRAINT assessment_search_address_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessment_statistics assessment_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_statistics
    ADD CONSTRAINT assessment_statistics_pkey PRIMARY KEY (id);


--
-- Name: assessments_address_id assessments_address_id_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments_address_id
    ADD CONSTRAINT assessments_address_id_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments_country_ids assessments_country_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments_country_ids
    ADD CONSTRAINT assessments_country_ids_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments_xml assessments_xml_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments_xml
    ADD CONSTRAINT assessments_xml_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessors assessors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessors
    ADD CONSTRAINT assessors_pkey PRIMARY KEY (scheme_assessor_id);


--
-- Name: assessors_status_events assessors_status_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessors_status_events
    ADD CONSTRAINT assessors_status_events_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (country_id);


--
-- Name: green_deal_assessments green_deal_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_assessments
    ADD CONSTRAINT green_deal_assessments_pkey PRIMARY KEY (green_deal_plan_id, assessment_id);


--
-- Name: green_deal_fuel_code_map green_deal_fuel_code_map_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_fuel_code_map
    ADD CONSTRAINT green_deal_fuel_code_map_pkey PRIMARY KEY (id);


--
-- Name: green_deal_fuel_price_data green_deal_fuel_price_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_fuel_price_data
    ADD CONSTRAINT green_deal_fuel_price_data_pkey PRIMARY KEY (id);


--
-- Name: green_deal_plans green_deal_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_plans
    ADD CONSTRAINT green_deal_plans_pkey PRIMARY KEY (green_deal_plan_id);


--
-- Name: linked_assessments linked_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.linked_assessments
    ADD CONSTRAINT linked_assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: open_data_logs open_data_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_data_logs
    ADD CONSTRAINT open_data_logs_pkey PRIMARY KEY (id);


--
-- Name: overridden_lodgement_events overridden_lodgement_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.overridden_lodgement_events
    ADD CONSTRAINT overridden_lodgement_events_pkey PRIMARY KEY (id);


--
-- Name: postcode_geolocation postcode_geolocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcode_geolocation
    ADD CONSTRAINT postcode_geolocation_pkey PRIMARY KEY (postcode);


--
-- Name: postcode_outcode_geolocations postcode_outcode_geolocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postcode_outcode_geolocations
    ADD CONSTRAINT postcode_outcode_geolocations_pkey PRIMARY KEY (outcode);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (scheme_id);


--
-- Name: assessment_search_address assessment_search_address_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessment_search_address
    ADD CONSTRAINT assessment_search_address_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments_address_id assessments_address_id_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments_address_id
    ADD CONSTRAINT assessments_address_id_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments_country_ids assessments_country_ids_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments_country_ids
    ADD CONSTRAINT assessments_country_ids_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: assessments_xml assessments_xml_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments_xml
    ADD CONSTRAINT assessments_xml_pkey PRIMARY KEY (assessment_id);


--
-- Name: green_deal_assessments green_deal_assessments_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.green_deal_assessments
    ADD CONSTRAINT green_deal_assessments_pkey PRIMARY KEY (green_deal_plan_id, assessment_id);


--
-- Name: linked_assessments linked_assessments_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.linked_assessments
    ADD CONSTRAINT linked_assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: overridden_lodgement_events overridden_lodgement_events_pkey; Type: CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.overridden_lodgement_events
    ADD CONSTRAINT overridden_lodgement_events_pkey PRIMARY KEY (id);


--
-- Name: index_address_base_on_address_line1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_base_on_address_line1 ON public.address_base USING btree (address_line1);


--
-- Name: index_address_base_on_address_line2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_base_on_address_line2 ON public.address_base USING btree (address_line2);


--
-- Name: index_address_base_on_postcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_base_on_postcode ON public.address_base USING btree (postcode);


--
-- Name: index_address_base_on_town; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_base_on_town ON public.address_base USING btree (town);


--
-- Name: index_address_base_versions_on_version_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_address_base_versions_on_version_number ON public.address_base_versions USING btree (version_number);


--
-- Name: index_address_on_assessment_search_address_trigram; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_address_on_assessment_search_address_trigram ON public.assessment_search_address USING gin (address public.gin_trgm_ops);


--
-- Name: index_assessment_statistics_on_assessments_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_statistics_on_assessments_count ON public.assessment_statistics USING btree (assessments_count);


--
-- Name: index_assessment_statistics_on_day_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_statistics_on_day_date ON public.assessment_statistics USING btree (day_date);


--
-- Name: index_assessment_statistics_on_rating_average; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessment_statistics_on_rating_average ON public.assessment_statistics USING btree (rating_average);


--
-- Name: index_assessment_statistics_unique_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_assessment_statistics_unique_group ON public.assessment_statistics USING btree (assessment_type, day_date, transaction_type, country);


--
-- Name: index_assessments_address_id_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_address_id_on_address_id ON public.assessments_address_id USING btree (address_id);


--
-- Name: index_assessments_country_ids_on_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_country_ids_on_country_id ON public.assessments_country_ids USING btree (country_id);


--
-- Name: index_assessments_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_address_id ON public.assessments USING btree (address_id);


--
-- Name: index_assessments_on_address_line1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_address_line1 ON public.assessments USING btree (lower((address_line1)::text));


--
-- Name: index_assessments_on_address_line2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_address_line2 ON public.assessments USING btree (lower((address_line2)::text));


--
-- Name: index_assessments_on_address_line3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_address_line3 ON public.assessments USING btree (lower((address_line3)::text));


--
-- Name: index_assessments_on_address_line4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_address_line4 ON public.assessments USING btree (lower((address_line4)::text));


--
-- Name: index_assessments_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_created_at ON public.assessments USING btree (created_at);


--
-- Name: index_assessments_on_postcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_postcode ON public.assessments USING btree (postcode);


--
-- Name: index_assessments_on_town; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_town ON public.assessments USING btree (lower((town)::text));


--
-- Name: index_assessments_on_type_of_assessment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessments_on_type_of_assessment ON public.assessments USING btree (type_of_assessment);


--
-- Name: index_assessors_on_registered_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessors_on_registered_by ON public.assessors USING btree (registered_by);


--
-- Name: index_assessors_on_search_results_comparison_postcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assessors_on_search_results_comparison_postcode ON public.assessors USING btree (search_results_comparison_postcode);


--
-- Name: index_audit_logs_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: index_audit_logs_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_event_type ON public.audit_logs USING btree (event_type);


--
-- Name: index_audit_logs_on_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- Name: index_green_deal_assessments_on_plan_id_and_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_green_deal_assessments_on_plan_id_and_assessment_id ON public.green_deal_assessments USING btree (green_deal_plan_id, assessment_id);


--
-- Name: index_linked_assessments_on_linked_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_linked_assessments_on_linked_assessment_id ON public.linked_assessments USING btree (linked_assessment_id);


--
-- Name: index_open_data_logs_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_open_data_logs_on_assessment_id ON public.open_data_logs USING btree (assessment_id);


--
-- Name: index_open_data_logs_on_task_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_open_data_logs_on_task_id ON public.open_data_logs USING btree (task_id);


--
-- Name: index_schemes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_schemes_on_name ON public.schemes USING btree (name);


--
-- Name: assessment_search_address_address_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessment_search_address_address_idx ON scotland.assessment_search_address USING gin (address);


--
-- Name: assessments_address_id_address_id_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_address_id_address_id_idx ON scotland.assessments_address_id USING btree (address_id);


--
-- Name: assessments_address_id_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_address_id_idx ON scotland.assessments USING btree (address_id);


--
-- Name: assessments_country_ids_country_id_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_country_ids_country_id_idx ON scotland.assessments_country_ids USING btree (country_id);


--
-- Name: assessments_created_at_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_created_at_idx ON scotland.assessments USING btree (created_at);


--
-- Name: assessments_lower_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_lower_idx ON scotland.assessments USING btree (lower((address_line1)::text));


--
-- Name: assessments_lower_idx1; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_lower_idx1 ON scotland.assessments USING btree (lower((address_line2)::text));


--
-- Name: assessments_lower_idx2; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_lower_idx2 ON scotland.assessments USING btree (lower((address_line3)::text));


--
-- Name: assessments_lower_idx3; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_lower_idx3 ON scotland.assessments USING btree (lower((address_line4)::text));


--
-- Name: assessments_lower_idx4; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_lower_idx4 ON scotland.assessments USING btree (lower((town)::text));


--
-- Name: assessments_postcode_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_postcode_idx ON scotland.assessments USING btree (postcode);


--
-- Name: assessments_type_of_assessment_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX assessments_type_of_assessment_idx ON scotland.assessments USING btree (type_of_assessment);


--
-- Name: green_deal_assessments_green_deal_plan_id_assessment_id_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE UNIQUE INDEX green_deal_assessments_green_deal_plan_id_assessment_id_idx ON scotland.green_deal_assessments USING btree (green_deal_plan_id, assessment_id);


--
-- Name: index_green_deal_plans_on_green_deal_plan_id; Type: INDEX; Schema: scotland; Owner: -
--

CREATE UNIQUE INDEX index_green_deal_plans_on_green_deal_plan_id ON scotland.green_deal_plans USING btree (green_deal_plan_id);


--
-- Name: linked_assessments_linked_assessment_id_idx; Type: INDEX; Schema: scotland; Owner: -
--

CREATE INDEX linked_assessments_linked_assessment_id_idx ON scotland.linked_assessments USING btree (linked_assessment_id);


--
-- Name: green_deal_assessments fk_assessment_id_assessments; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_assessments
    ADD CONSTRAINT fk_assessment_id_assessments FOREIGN KEY (assessment_id) REFERENCES public.assessments(assessment_id);


--
-- Name: green_deal_assessments fk_green_deal_plan_id_green_deal_plans; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.green_deal_assessments
    ADD CONSTRAINT fk_green_deal_plan_id_green_deal_plans FOREIGN KEY (green_deal_plan_id) REFERENCES public.green_deal_plans(green_deal_plan_id) ON DELETE CASCADE;


--
-- Name: assessments fk_rails_2b3426e6d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT fk_rails_2b3426e6d8 FOREIGN KEY (scheme_assessor_id) REFERENCES public.assessors(scheme_assessor_id);


--
-- Name: assessors fk_rails_701e01cf72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessors
    ADD CONSTRAINT fk_rails_701e01cf72 FOREIGN KEY (registered_by) REFERENCES public.schemes(scheme_id);


--
-- Name: assessments_xml fk_rails_ded04cac6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments_xml
    ADD CONSTRAINT fk_rails_ded04cac6b FOREIGN KEY (assessment_id) REFERENCES public.assessments(assessment_id);


--
-- Name: assessments_country_ids fks_assessments_country_ids_countries; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments_country_ids
    ADD CONSTRAINT fks_assessments_country_ids_countries FOREIGN KEY (country_id) REFERENCES public.countries(country_id);


--
-- Name: green_deal_assessments fk_rails_39f982bf8a; Type: FK CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.green_deal_assessments
    ADD CONSTRAINT fk_rails_39f982bf8a FOREIGN KEY (green_deal_plan_id) REFERENCES scotland.green_deal_plans(green_deal_plan_id);


--
-- Name: assessments fk_rails_403ecd00b2; Type: FK CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments
    ADD CONSTRAINT fk_rails_403ecd00b2 FOREIGN KEY (scheme_assessor_id) REFERENCES public.assessors(scheme_assessor_id);


--
-- Name: assessments_xml fk_scotland_assessment_xml_scotland_assessments; Type: FK CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments_xml
    ADD CONSTRAINT fk_scotland_assessment_xml_scotland_assessments FOREIGN KEY (assessment_id) REFERENCES scotland.assessments(assessment_id);


--
-- Name: green_deal_assessments fk_scotland_green_deal_assessments_scotland_assessments; Type: FK CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.green_deal_assessments
    ADD CONSTRAINT fk_scotland_green_deal_assessments_scotland_assessments FOREIGN KEY (assessment_id) REFERENCES scotland.assessments(assessment_id);


--
-- Name: assessments_country_ids fks_assessments_country_ids_countries; Type: FK CONSTRAINT; Schema: scotland; Owner: -
--

ALTER TABLE ONLY scotland.assessments_country_ids
    ADD CONSTRAINT fks_assessments_country_ids_countries FOREIGN KEY (country_id) REFERENCES public.countries(country_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO public,scotland;

INSERT INTO "schema_migrations" (version) VALUES
('20260722083729'),
('20260609151447'),
('20260311120732'),
('20260305113834'),
('20260115152511'),
('20260108092829'),
('20251111135429'),
('20251107120548'),
('20250922151938'),
('20250922145129'),
('20250922141707'),
('20250922132926'),
('20250911134216'),
('20250911105832'),
('20250811143346'),
('20240819144800'),
('20240606094342'),
('20240603084423'),
('20240603083906'),
('20240523081837'),
('20240520110407'),
('20240516131516'),
('20240306155420'),
('20240228150058'),
('20240228120412'),
('20240216120340'),
('20231108111654'),
('20230619095823'),
('20230619095143'),
('20230616123424'),
('20230616083615'),
('20230607184720'),
('20230607084849'),
('20230605140351'),
('20230516134159'),
('20230515132707'),
('20230111093615'),
('20221222194606'),
('20220908144140'),
('20220808135701'),
('20220803110916'),
('20220223171518'),
('20220105152327'),
('20211201094303'),
('20211124152645'),
('20211119113727'),
('20211119104517'),
('20211109124947'),
('20211109093636'),
('20211103142738'),
('20211027112429'),
('20211022130717'),
('20211022092711'),
('20210914083822'),
('20210913110930'),
('20210913110802'),
('20210913105243'),
('20210715142113'),
('20210511111424'),
('20210210155650'),
('20210209150314'),
('20210209095218'),
('20210208140745'),
('20201217153000'),
('20201125105700'),
('20201117162600'),
('20201029103910'),
('20201005145253'),
('20201005145252'),
('20201005133700'),
('20200924235959'),
('20200921152957'),
('20200921110823'),
('20200918173725'),
('20200916235959'),
('20200915081959'),
('20200826175349'),
('20200826170404'),
('20200826165137'),
('20200826162333'),
('20200820101620'),
('20200819165600'),
('20200819164958'),
('20200819163923'),
('20200819163143'),
('20200819153132'),
('20200819122703'),
('20200819113347'),
('20200817135249'),
('20200817102504'),
('20200806113333'),
('20200806111735'),
('20200802163906'),
('20200730110134'),
('20200728102954'),
('20200722102954'),
('20200721131250'),
('20200714115002'),
('20200714113545'),
('20200712150211'),
('20200708110248'),
('20200707110950'),
('20200626133406'),
('20200623143510'),
('20200622115542'),
('20200622100940'),
('20200617142535'),
('20200617142016'),
('20200617141341'),
('20200616125947'),
('20200616104452'),
('20200612092930'),
('20200610102916'),
('20200610095648'),
('20200610094938'),
('20200609150905'),
('20200608151350'),
('20200608140759'),
('20200608133739'),
('20200608125912'),
('20200604115108'),
('20200603205332'),
('20200603122802'),
('20200603122540'),
('20200603122416'),
('20200603122138'),
('20200603115826'),
('20200603113901'),
('20200602151358'),
('20200601113826'),
('20200520132641'),
('20200520130527'),
('20200519132058'),
('20200519131145'),
('20200518123727'),
('20200514115407'),
('20200513085854'),
('20200512134243'),
('20200506140733'),
('20200430120438'),
('20200430103004'),
('20200429113650'),
('20200427131428'),
('20200424154936'),
('20200416115941'),
('20200416091957'),
('20200416082806'),
('20200415103518'),
('20200415074714'),
('20200408115235'),
('20200408112947'),
('20200408103550'),
('20200408093743'),
('20200403084606'),
('20200331100511'),
('20200326133853'),
('20200326131837'),
('20200325141433'),
('20200317111928'),
('20200311142056'),
('20200309142931'),
('20200304104905'),
('20200302131954'),
('20200302123538'),
('20200227094053'),
('20200211172559'),
('20200211112211'),
('20200211104126'),
('20200203125126'),
('20200128125200'),
('20200128103751'),
('20200122152714'),
('20200122111750'),
('20200122111657'),
('20200113165959'),
('20200113165013'),
('20200113163913'),
('20200113142843'),
('20200108160946'),
('20200108152717'),
('20200107162305'),
('20191212150246'),
('20191203162034'),
('20191127191652'),
('20191120133528');

